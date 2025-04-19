from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash
from supabase import create_client, Client
from dotenv import load_dotenv
import os

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
# Run the app
# -------------------------------
if __name__ == '__main__':
    app.run(debug=True)
