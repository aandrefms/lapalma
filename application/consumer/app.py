from flask import Flask, jsonify, request, g
import os
import json
from random import randint
from prometheus_flask_exporter import PrometheusMetrics
import uuid
import logging
from logger_config import setup_logger, set_traceid
import boto3 
import threading

app = Flask(__name__)
metrics = PrometheusMetrics(app)

logger = setup_logger()
app.logger.handlers = []
app.logger.propagate = True
app.logger.addHandler(logger.handlers[0])

sqs_client = boto3.client('sqs', region_name='us-east-1')
queue_url = 'https://sqs.us-east-1.amazonaws.com/278933246619/application-sqs'

def poll_sqs():
    while True:
        try:
            response = sqs_client.receive_message(
                QueueUrl=queue_url,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20,
                MessageAttributeNames=['All']  # Ensure all message attributes are received
            )
            messages = response.get('Messages', [])
            for message in messages:
                
                body = json.loads(message['Body'])
                traceparent = body.get('MessageAttributes', {}).get('traceparent', {}).get('Value', 'N/A')
                set_traceid(traceparent)
                process_message(body['Message'])
                sqs_client.delete_message(
                    QueueUrl=queue_url,
                    ReceiptHandle=message['ReceiptHandle']
                )
        except Exception as e:
            logger.error(f"Error receiving message: {e}")

def process_message(message):
    logger.info(f"Processing message successfully:")

@app.route('/')
def home():
    return jsonify({"status": "SQS Consumer is running"})

if __name__ == '__main__':
    polling_thread = threading.Thread(target=poll_sqs)
    polling_thread.daemon = True
    polling_thread.start()

    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5001)))
