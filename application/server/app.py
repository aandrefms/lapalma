from flask import Flask, jsonify, request, g
import os
from random import randint
from prometheus_flask_exporter import PrometheusMetrics
import uuid
import logging
from logger_config import setup_logger
import boto3
import time

app = Flask(__name__)
metrics = PrometheusMetrics(app)

logger = setup_logger()
app.logger.handlers = []
app.logger.propagate = True
app.logger.addHandler(logger.handlers[0])

@app.before_request
def set_traceid_and_log_request():
    traceid = request.headers.get('X-Trace-Id', str(uuid.uuid4()))
    g.traceid = traceid
    g.start_time = time.time()
    
    client_info = request.headers.get('User-Agent', 'unknown-client')
    request_body = request.get_json(silent=True) or {}
    
    log_params = {
        "method": request.method,
        "url": request.url,
        "client": client_info,
        "body": request_body
    }
    logger.info(f"[request] - method={log_params['method']}, url={log_params['url']}, client={log_params['client']}, body={log_params['body']}")


@app.after_request
def log_request_response(response):
    duration = round((time.time() - g.start_time) * 1000)  # duration in ms
    log_params = {
        "method": request.method,
        "url": request.url,
        "status": response.status_code,
        "code": response.status_code,
        "duration": f"{duration} ms"
    }
    logger.info(f"[response] - method={log_params['method']}, url={log_params['url']}, status={log_params['status']}, code={log_params['code']}, duration={log_params['duration']}")
    return response

@app.route('/', methods=['GET'])
def roll_dice():
    dice_value = randint(1, 6)
    logger.info('Dice rolled with value: %d', dice_value)
    test_trace()
    return jsonify({'dice_value': dice_value})

def test_trace():
    logger.info("Calling another function just to test traceid implementation")

@app.route("/fail")
def fail():
    try:
        1/0
    except Exception as e:
        logger.error('Error occurred: %s', str(e))
        raise
    return 'fail'

@app.route('/publish')
def publish_message(topic_arn='application-sns'):
    
    try:
        sns_client = boto3.client('sns', region_name='us-east-1')
        topic_arn = 'arn:aws:sns:us-east-1:278933246619:application-sns'
        traceid = getattr(g, 'traceid', 'N/A')
        response = sns_client.publish(
            TopicArn=topic_arn,
            Message="Just testing SQS implementation",
            MessageAttributes={
                "traceparent": {
                    "DataType": "String",
                    "StringValue": traceid
                }
            }
        )
        logger.info(f"Published message")
        return jsonify(response), 200
    except Exception as e:
        logger.error(f"Failed to publish message: {e}")
        return jsonify({'error': str(e)}), 500

@app.errorhandler(500)
def handle_500(error):
    logger.error('Handling 500 error: %s', str(error))
    return str(error), 500

if __name__ == '__main__':
    with app.app_context():
        app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
