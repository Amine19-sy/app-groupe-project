from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from supabase import create_client
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({"message": "The backend is working"})

# -------------------------------
# Register startpoint
# -------------------------------
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    if not all(k in data for k in ("username", "email", "password")):
        return jsonify({"error": "Missing required fields"}), 400

    username = data['username']
    email = data['email']
    password = data['password']

    try:
        # Step 1: Create user in Supabase Auth
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password
        })

        if not auth_response or not auth_response.user:
            return jsonify({"error": "Auth registration failed"}), 400

        supabase_uid = auth_response.user.id  # Save the UID in case we need to delete

        # Step 2: Insert into custom User table
        password_hash = generate_password_hash(password)
        insert_response = supabase.table("User").insert({
            "username": username,
            "email": email,
            "password_hash": password_hash
        }).execute()

        if not insert_response.data:
            # If failed, rollback: delete user from Supabase Auth
            supabase.auth.admin.delete_user(supabase_uid)
            return jsonify({"error": "User already exists in table or insertion failed"}), 400

        return jsonify({
            "message": "User created successfully",
            "user": insert_response.data
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
# -------------------------------
# Register endpoint
# -------------------------------

# -------------------------------
# Login startpoint
# -------------------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not all(k in data for k in ("email", "password")):
        return jsonify({"error": "Missing email or password"}), 400

    email = data['email']
    password = data['password']

    try:
        # Step 1: Auth via Supabase Auth
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

        # Check if login failed
        if not auth_response or not auth_response.user:
            return jsonify({"error": "Invalid credentials"}), 401

        # Step 2: Fetch user info from custom table
        user_data = supabase.table("User").select("*").eq("email", email).single().execute()

        if not user_data or not user_data.data:
            return jsonify({"error": "User found in Auth but not in custom table"}), 404

        return jsonify({
            "message": "Login successful",
            "user": user_data.data,
            "access_token": auth_response.session.access_token
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500 
# -------------------------------
# Login endpoint
# -------------------------------

# -------------------------------
# Items endpoints
# -------------------------------

@app.route('/api/items', methods=['GET'])
def get_items():
    box_id = request.args.get('box_id')
    if not box_id:
        return jsonify({'error': 'Missing box_id parameter'}), 400

    try:
        response = supabase.table("Item").select("*").eq("box_id", box_id).execute()
        return jsonify(response.data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/add_item', methods=['POST'])
def add_item():
    data = request.get_json()
    required_fields = ['box_id', 'name']
    if not data or not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields: box_id and name'}), 400

    try:
        # Insert item
        item_response = supabase.table("Item").insert({
            "box_id": data["box_id"],
            "name": data["name"],
            "quantity": data.get("quantity", 1)
        }).execute()

        if not item_response.data:
            return jsonify({"error": "Failed to add item"}), 400

        item = item_response.data[0]

        # Fetch box to get user_id
        box_info = supabase.table("Box").select("user_id").eq("id", item["box_id"]).single().execute()

        # Add to history
        supabase.table("History").insert({
            "user_id": box_info.data["user_id"],
            "box_id": item["box_id"],
            "item_id": item["id"],
            "action_type": "ADD_ITEM",
            "details": f"Added item {item['name']}"
        }).execute()

        return jsonify(item), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/remove_item/<int:item_id>', methods=['DELETE'])
def remove_item(item_id):
    try:
        # Get the item
        item_response = supabase.table("Item").select("*").eq("id", item_id).single().execute()
        item = item_response.data

        if not item:
            return jsonify({"error": "Item not found"}), 404

        # Get the box
        box_response = supabase.table("Box").select("user_id").eq("id", item["box_id"]).single().execute()
        box = box_response.data

        if not box:
            return jsonify({"error": "Box not found"}), 404

        # Delete the item
        supabase.table("Item").delete().eq("id", item_id).execute()

        # Add to history
        supabase.table("History").insert({
            "user_id": box["user_id"],
            "box_id": item["box_id"],
            "item_id": item["id"],
            "action_type": "REMOVE_ITEM",
            "details": f"Removed item {item['name']}"
        }).execute()

        return jsonify({"message": "Item removed successfully."}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/history/<int:box_id>', methods=['GET'])
def get_history_by_box(box_id):
    try:
        response = supabase.table("History").select("*").eq("box_id", box_id).order("action_time", desc=True).execute()
        return jsonify(response.data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/boxes', methods=['GET'])
def get_all_boxes():
    response = supabase.table("Box").select("*").execute()
    return jsonify(response.data), 200


# -------------------------------
# Run the app
# -------------------------------
if __name__ == '__main__':
    app.run(debug=True)