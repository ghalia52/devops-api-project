import pytest
import json
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.app import app, items  # ADD items here

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        items.clear()  # Clear before each test
        yield client
        items.clear()  # Clear after each test

def test_health_check(client):
    """Test health endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'timestamp' in data

def test_get_items_empty(client):
    """Test getting items when list is empty"""
    response = client.get('/api/items')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert isinstance(data['items'], list)
    assert 'count' in data

def test_create_item(client):
    """Test creating a new item"""
    response = client.post('/api/items',
                          data=json.dumps({'name': 'Test Item', 'description': 'A test'}),
                          content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['name'] == 'Test Item'
    assert data['description'] == 'A test'
    assert 'id' in data

def test_create_item_without_name(client):
    """Test creating item without required name field"""
    response = client.post('/api/items',
                          data=json.dumps({'description': 'No name'}),
                          content_type='application/json')
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'error' in data

def test_get_single_item(client):
    """Test getting a single item"""
    # Create an item first
    create_response = client.post('/api/items',
                                  data=json.dumps({'name': 'Item 1'}),
                                  content_type='application/json')
    item_data = json.loads(create_response.data)
    
    # Use the actual ID from the created item
    response = client.get(f'/api/items/{item_data["id"]}')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['name'] == 'Item 1'

def test_get_nonexistent_item(client):
    """Test getting an item that doesn't exist"""
    response = client.get('/api/items/999')
    assert response.status_code == 404
    data = json.loads(response.data)
    assert 'error' in data

def test_update_item(client):
    """Test updating an item"""
    # Create an item first
    create_response = client.post('/api/items',
                                  data=json.dumps({'name': 'Original'}),
                                  content_type='application/json')
    item_data = json.loads(create_response.data)
    
    # Update it using the actual ID
    response = client.put(f'/api/items/{item_data["id"]}',
                         data=json.dumps({'name': 'Updated'}),
                         content_type='application/json')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['name'] == 'Updated'

def test_update_nonexistent_item(client):
    """Test updating an item that doesn't exist"""
    response = client.put('/api/items/999',
                         data=json.dumps({'name': 'Updated'}),
                         content_type='application/json')
    assert response.status_code == 404

def test_delete_item(client):
    """Test deleting an item"""
    # Create an item first
    create_response = client.post('/api/items',
                                  data=json.dumps({'name': 'To Delete'}),
                                  content_type='application/json')
    item_data = json.loads(create_response.data)
    
    # Delete it using the actual ID
    response = client.delete(f'/api/items/{item_data["id"]}')
    assert response.status_code == 200
    
    # Verify it's gone
    response = client.get(f'/api/items/{item_data["id"]}')
    assert response.status_code == 404

def test_delete_nonexistent_item(client):
    """Test deleting an item that doesn't exist"""
    response = client.delete('/api/items/999')
    assert response.status_code == 404

def test_logging_with_trace_id(client):
    """Test that requests include trace IDs"""
    response = client.get('/health', headers={'X-Trace-ID': 'test-trace-123'})
    assert response.status_code == 200