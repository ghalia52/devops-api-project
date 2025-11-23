from flask import Flask, jsonify, request
import logging
import json
import os
import time
import uuid
from datetime import datetime
from prometheus_flask_exporter import PrometheusMetrics
# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Application info', version='1.0.0')
# In-memory storage
items = []

# Middleware for request logging with trace ID
@app.before_request
def log_request():
    trace_id = request.headers.get('X-Trace-ID', str(uuid.uuid4()))
    request.trace_id = trace_id
    request.start_time = time.time()
    
    logger.info(json.dumps({
        'message': 'Incoming request',
        'method': request.method,
        'path': request.path,
        'trace_id': trace_id,
        'timestamp': datetime.utcnow().isoformat()
    }))

@app.after_request
def log_response(response):
    duration = time.time() - request.start_time
    logger.info(json.dumps({
        'message': 'Request completed',
        'method': request.method,
        'path': request.path,
        'status_code': response.status_code,
        'duration_seconds': round(duration, 3),
        'trace_id': request.trace_id,
        'timestamp': datetime.utcnow().isoformat()
    }))
    return response

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'devops-api'
    }), 200

# List all items
@app.route('/api/items', methods=['GET'])
def get_items():
    return jsonify({
        'items': items,
        'count': len(items)
    }), 200

# Create new item
@app.route('/api/items', methods=['POST'])
def create_item():
    if not request.json or 'name' not in request.json:
        return jsonify({'error': 'Name is required'}), 400
    
    item = {
        'id': len(items) + 1,
        'name': request.json['name'],
        'description': request.json.get('description', ''),
        'created_at': datetime.utcnow().isoformat()
    }
    items.append(item)
    
    logger.info(json.dumps({
        'message': 'Item created',
        'item_id': item['id'],
        'trace_id': request.trace_id
    }))
    
    return jsonify(item), 201

# Get single item
@app.route('/api/items/<int:item_id>', methods=['GET'])
def get_item(item_id):
    item = next((item for item in items if item['id'] == item_id), None)
    if not item:
        return jsonify({'error': 'Item not found'}), 404
    return jsonify(item), 200

# Update item
@app.route('/api/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    item = next((item for item in items if item['id'] == item_id), None)
    if not item:
        return jsonify({'error': 'Item not found'}), 404
    
    if request.json.get('name'):
        item['name'] = request.json['name']
    if request.json.get('description'):
        item['description'] = request.json['description']
    item['updated_at'] = datetime.utcnow().isoformat()
    
    return jsonify(item), 200

# Delete item
@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    global items
    item = next((item for item in items if item['id'] == item_id), None)
    if not item:
        return jsonify({'error': 'Item not found'}), 404
    
    items = [i for i in items if i['id'] != item_id]
    return jsonify({'message': 'Item deleted', 'id': item_id}), 200

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
