import base64
import os
from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash
from supabase import create_client, Client
from dotenv import load_dotenv
from supabase.lib.client_options import ClientOptions

# Load environment variables from .env
load_dotenv()

# Initialize Supabase client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Supabase credentials not found. Check your .env file.")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Initialize Flask app
app = Flask(__name__)

# -------------------------------
# Register endpoint
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
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password
        })

        if not auth_response or not auth_response.user:
            return jsonify({"error": "Auth registration failed"}), 400

        supabase_uid = auth_response.user.id
        password_hash = generate_password_hash(password)

        insert_response = supabase.table("User").insert({
            "username": username,
            "email": email,
            "password_hash": password_hash
        }).execute()

        if not insert_response.data:
            supabase.auth.admin.delete_user(supabase_uid)
            return jsonify({"error": "User already exists or insert failed"}), 400

        return jsonify({
            "message": "User created successfully",
            "user": insert_response.data
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------
# Login endpoint
# -------------------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not all(k in data for k in ("email", "password")):
        return jsonify({"error": "Missing email or password"}), 400

    email = data['email']
    password = data['password']

    try:
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

        if not auth_response or not auth_response.user:
            return jsonify({"error": "Invalid credentials"}), 401

        user_data = supabase.table("User").select("*").eq("email", email).single().execute()

        if not user_data or not user_data.data:
            return jsonify({"error": "User found in Auth but not in table"}), 404

        return jsonify({
            "message": "Login successful",
            "user": user_data.data,
            "access_token": auth_response.session.access_token
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------
# Box endpoints
# -------------------------------
@app.route('/api/add_box', methods=['POST'])
def add_box():
    try:
        token = request.headers.get("Authorization")
        if not token:
            return jsonify({"error": "Missing token"}), 401

        user_supabase = create_client(
            SUPABASE_URL, SUPABASE_KEY,
            options=ClientOptions(headers={"Authorization": token})
        )

        name = request.form.get('name')
        description = request.form.get('description')
        user_id = request.form.get('user_id')
        is_open = request.form.get('is_open', 'false').lower() == 'true'

        image_file = request.files.get('image')
        image_data = image_file.read() if image_file else None

        box_data = {
            "name": name,
            "description": description,
            "user_id": int(user_id),
            "is_open": is_open
        }

        if image_data:
            box_data["image"] = image_data

        response = user_supabase.table("Box").insert(box_data).execute()
        box = response.data[0]

        # ✅ Corriger ici pour gérer l'absence d'image
        image_field = box.get("image")
        if image_field is not None:
            box["image"] = base64.b64encode(image_field).decode('utf-8')
        else:
            box["image"] = None

        return jsonify(box), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/box/<int:box_id>', methods=['GET'])
def get_box(box_id):
    try:
        response = supabase.table("Box").select("*").eq("id", box_id).single().execute()
        box = response.data
        if not box:
            return jsonify({"error": "Box not found"}), 404

        image_data = box.get("image")
        if image_data is not None:
            box["image"] = base64.b64encode(image_data).decode('utf-8')
        else:
            box["image"] = None


        return jsonify(box), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/update_box_image/<int:box_id>', methods=['PUT'])
def update_box_image(box_id):
    try:
        image_file = request.files.get('image')
        if not image_file:
            return jsonify({"error": "No image uploaded"}), 400

        image_data = image_file.read()

        supabase.table("Box").update({
            "image": image_data
        }).eq("id", box_id).execute()

        return jsonify({"message": "Image updated"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/remove_box_image/<int:box_id>', methods=['DELETE'])
def remove_box_image(box_id):
    try:
        supabase.table("Box").update({"image": None}).eq("id", box_id).execute()
        return jsonify({"message": "Image removed"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/delete_box/<int:box_id>', methods=['DELETE'])
def delete_box(box_id):
    try:
        supabase.table("Box").delete().eq("id", box_id).execute()
        return jsonify({"message": "Box deleted"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------
# Run the app
# -------------------------------
if __name__ == '__main__':
    app.run(debug=True)
