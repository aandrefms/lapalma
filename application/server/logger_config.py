import logging
import json
from flask import g, request
import time
import os

class JSONFormatter(logging.Formatter):
    def format(self, record):
        record.traceid = getattr(g, 'traceid', '')
        record.pod_name = os.getenv('POD_NAME', '')
        record.app_name = os.getenv('APP_NAME', '')
        log_record = {
            'timestamp': self.formatTime(record, self.datefmt),
            'traceid': record.traceid,
            'app_name': record.app_name,
            'pod_name': record.pod_name,
            'level': record.levelname,
            'message': record.getMessage(),
        }
        return json.dumps(log_record)

def setup_logger():
    formatter = JSONFormatter()

    handler = logging.StreamHandler()
    handler.setFormatter(formatter)

    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    logger.addHandler(handler)

    werkzeug_logger = logging.getLogger('werkzeug')
    werkzeug_logger.setLevel(logging.ERROR)
    werkzeug_handler = logging.StreamHandler()
    werkzeug_handler.setFormatter(formatter)
    werkzeug_logger.handlers = [werkzeug_handler]

    return logger

def set_traceid(traceid):
    logger = logging.getLogger(__name__)
    for handler in logger.handlers:
        handler.addFilter(lambda record: setattr(record, 'traceid', traceid) or True)