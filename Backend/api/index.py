from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from supabase import create_client
import os
from dotenv import load_dotenv
import base64

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
# ID de la Box 
BOX_ID = 1 

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
# Box endpoints
# -------------------------------
@app.route('/api/add_box', methods=['POST'])
def add_box():
    try:
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

        response = supabase.table("Box").insert(box_data).execute()
        box = response.data[0]

        # 🔥 ENCODE the image if exists to avoid serialization issues
        if box.get("image"):
            import base64
            box["image"] = base64.b64encode(box["image"]).decode('utf-8')

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

        if box.get("image"):
            box["image"] = base64.b64encode(box["image"]).decode('utf-8')

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

#########################################################
@app.route('/api/send_command', methods=['POST'])
def send_command():
    try:
        data = request.get_json()
        command = data.get("command")
        box_id = data.get("box_id")

        if not command or not box_id:
            return jsonify({"error": "Missing 'command' or 'box_id'"}), 400

        result = supabase.table("commands").insert({
            "command": command,
            "box_id": box_id
        }).execute()

        if result.status_code == 201:
            return jsonify({"message": f"Command '{command}' sent to box {box_id}"}), 201
        else:
            return jsonify({"error": "Failed to insert command"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------
# Run the app
# -------------------------------
if __name__ == '__main__':
    app.run(debug=True)