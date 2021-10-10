import json
from fastapi.testclient import TestClient
from app import app

client = TestClient(app)

post_data_valid = {
    "id": 987,
    "name": "test_name",
    "comment": "test_comment",
    "imageUrl": "https://www.example.com/",
    "value": "test_value",
    "yumFactor": 5
}

post_data_invalid = {
    "id": 654,
    "name": "test_name",
    "comment": "test_comment",
    "imageUrl": "https://www.example.com/",
    "value": "test_value",
    "yumFactor": "invalid_id"
}


def test_post_create_ok():
    response = client.post("/create", json.dumps(post_data_valid))
    assert response.status_code == 201
    assert response.json() == post_data_valid


def test_post_create_validation_error():
    response = client.post("/create", json.dumps(post_data_invalid))
    assert response.status_code == 422


def test_post_create_duplicate():
    response = client.post("/create", json.dumps(post_data_valid))
    assert response.status_code == 409


def test_get_list_ok():
    response = client.get("/list")
    assert response.status_code == 200
    assert response.json() is not None
    assert len(response.json()) == 1


def test_delete():
    response = client.delete("/delete/987")
    assert response.status_code == 204
