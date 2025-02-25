import requests
import pytest

BASE_URL = "http://127.0.0.1:8080"

def test_health_check_success():
    """Test if the /healthz endpoint returns 200 OK when no params or body are sent"""
    response = requests.get(f"{BASE_URL}/healthz")
    assert response.status_code == 200

# def test_health_check_db_failure():
#     """Ensure the /healthz endpoint returns 503 when DB insertion fails"""

#     # Mock insert_health_check() to raise an Exception
#     with patch("app.services.health_check_service.insert_health_check", Exception("Mocked DB Error")):
#         response = requests.get(f"{BASE_URL}/healthz")

#         # Debugging: Print response details
#         print(f"Response status code: {response.status_code}")
#         print(f"Response body: {response.text}")

#         assert response.status_code == 503

def test_health_check_bad_request_with_query_params():
    """Test if sending query parameters in a GET request returns 400 Bad Request"""
    response = requests.get(f"{BASE_URL}/healthz", params={"1": "hello"})
    assert response.status_code == 400

def test_health_check_bad_request_with_body():
    """Test if sending a body in a GET request returns 400 Bad Request"""
    response = requests.get(f"{BASE_URL}/healthz", json={"name": "tharun"})
    print(response.status_code)
    assert response.status_code == 400

def test_health_check_method_not_allowed():
    """Test that POST, PUT, DELETE, PATCH return 405 Method Not Allowed"""
    for method in ["post", "put", "delete", "patch"]:
        response = getattr(requests, method)(f"{BASE_URL}/healthz")
        print(response.status_code)
        assert response.status_code == 405

if __name__ == "__main__":
    import pytest
    pytest.main(["-v", "test_api.py"])
