import requests

BASE_URL = "http://127.0.0.1:5000"


def login_get_user():
    response = requests.post(f"{BASE_URL}/login", json={
        "email": "admin@example.com",
        "password": "admin123"
    })

    assert response.status_code == 200, "Login failed"
    data = response.json()
    user = data["user"]
    token = data["access_token"]
    return user["id"], token


def test_add_box(user_id, token):
    url = f"{BASE_URL}/api/add_box"
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "name": "Test Box",
        "description": "Box without image",
        "user_id": user_id,
        "is_open": "true"
    }

    response = requests.post(url, data=data, headers=headers)
    print("📦 Add Box:", response.status_code)
    try:
        res_data = response.json()
        print("📦 Response:", res_data)
        return res_data["id"]
    except Exception as e:
        print("❌ Failed to decode response:", response.text)
        raise e


def test_get_box(box_id, token):
    url = f"{BASE_URL}/api/box/{box_id}"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    print("📥 Get Box:", response.status_code, response.json())


def test_delete_box(box_id, token):
    url = f"{BASE_URL}/api/delete_box/{box_id}"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.delete(url, headers=headers)
    print("🧹 Delete Box:", response.status_code, response.json())


if __name__ == "__main__":
    print("🔐 Logging in and retrieving user...")
    user_id, token = login_get_user()

    print("\n📦 Adding box without image...")
    box_id = test_add_box(user_id, token)

    print("\n📥 Getting box data...")
    test_get_box(box_id, token)

    print("\n🧹 Deleting test box...")
    test_delete_box(box_id, token)

    print("\n✅ Test completed successfully (no image involved).")
