from flask import Blueprint, request, jsonify
from extensions import db,jwt
from models.user import User
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from flask import current_app

auth_bp = Blueprint('auth', __name__)



@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # Check if all required fields are provided
    if not all(k in data for k in ("username", "email", "password" )):
        print("not provided")
        return jsonify({"error": "Missing required fields"}), 400

    username = data['username']
    email = data['email']
    password = data['password']


    # Check if user with same username or email exists
    if User.query.filter((User.username == username) | (User.email == email)).first():
        print("here")
        return jsonify({"error": "User already exists"}), 400

    # Create a new user and hash the password
    password_hash = generate_password_hash(password)
    new_user = User(username=username, email=email, password_hash=password_hash)
    
    db.session.add(new_user)
    db.session.commit()
    access_token = create_access_token(identity=str(new_user.id))
    return jsonify({"access_token": access_token,
                    "user": new_user.to_dict()}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not all(k in data for k in ("username", "password")):
        return jsonify({"error": "Missing username or password"}), 400

    username = data['username']
    password = data['password']

    user = User.query.filter_by(username=username).first()
    if user and check_password_hash(user.password_hash, password):
        access_token = create_access_token(identity=str(user.id))
        return jsonify({"access_token": access_token
                        ,"user": user.to_dict()}), 200
    else:
        return jsonify({"error": "Invalid username or password"}), 401

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    # grab the user ID out of the validated JWT
    user_id = get_jwt_identity()
    
    # fetch from DB
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    # return the same dict you used in register/login
    return jsonify({"user": user.to_dict()}), 200

@jwt.unauthorized_loader
def missing_token_callback(error_string):
    current_app.logger.error(f"[JWT ERROR] Missing token: {error_string}")
    return jsonify({"error": "Missing Authorization token", "detail": error_string}), 401

# Handle invalid token (malformed, wrong signature, etc.)
@jwt.invalid_token_loader
def invalid_token_callback(error_string):
    current_app.logger.error(f"[JWT ERROR] Invalid token: {error_string}")
    return jsonify({"error": "Invalid token", "detail": error_string}), 401

# Handle expired token
@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    user_id = jwt_payload.get('sub', 'unknown')
    current_app.logger.error(f"[JWT ERROR] Expired token for user ID: {user_id}")
    return jsonify({"error": "Token expired"}), 401

# Handle fresh token required (if you use @fresh_jwt_required)
@jwt.needs_fresh_token_loader
def needs_fresh_token_callback(jwt_header, jwt_payload):
    current_app.logger.error("[JWT ERROR] Fresh token required")
    return jsonify({"error": "Fresh token required"}), 401

# Handle revoked token (if you use token revoking)
@jwt.revoked_token_loader
def revoked_token_callback(jwt_header, jwt_payload):
    current_app.logger.error("[JWT ERROR] Token has been revoked")
    return jsonify({"error": "Token has been revoked"}), 401