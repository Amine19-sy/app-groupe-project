import requests

BASE_URL = "http://127.0.0.1:5000"

def test_login():
    url = f"{BASE_URL}/login"
    payload = {
        "email": "admin@example.com",
        "password": "admin123"
    }

    response = requests.post(url, json=payload)
    print("Status Code:", response.status_code)
    print("Response:", response.json())

if __name__ == "__main__":
    test_login()
