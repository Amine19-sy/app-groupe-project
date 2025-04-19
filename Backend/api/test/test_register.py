import requests

# Replace with the actual address where your Flask app is running
BASE_URL = "http://127.0.0.1:5000"

def test_register():
    url = f"{BASE_URL}/register"
    payload = {
        "username": "admin",
        "email": "admin@example.com",
        "password": "admin123"
    }

    response = requests.post(url, json=payload)

    print("Status Code:", response.status_code)
    try:
        print("Response:", response.json())
    except:
        print("Raw Response:", response.text)

if __name__ == "__main__":
    test_register()
