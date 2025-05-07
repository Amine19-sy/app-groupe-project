from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os
from flask_cors import CORS
from datetime import datetime
import uuid
from flask import send_from_directory
from sqlalchemy import or_
from enum import Enum
from flask_jwt_extended import JWTManager, create_access_token ,jwt_required, get_jwt_identity



app = Flask(__name__)
CORS(app)
# Configure the SQLite database location
basedir = os.path.abspath(os.path.dirname(__file__))
db_path = os.path.join(basedir, 'db.sqlite')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + db_path
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
#Configure jwt tokens 
app.config["JWT_SECRET_KEY"] = "c30fc7aae7233ec923231b0e7d562f24f5901c381c593cb0d01d3e847f2d3beb"  
jwt = JWTManager(app)

db = SQLAlchemy(app)

# ---------------------
# User Model
# ---------------------
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.Text, nullable=False)
    
    # Relationships
    boxes = db.relationship('Box', backref='owner', lazy=True, cascade="all, delete-orphan")
    histories = db.relationship('History', backref='user', lazy=True, cascade="all, delete-orphan")
    
    def to_dict(self):
        return {'id': self.id, 'username': self.username, 'email': self.email}

# ---------------------
# Box Model
# ---------------------
class Box(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)  
    description = db.Column(db.String(255), nullable=True)  # New description field
    is_open = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    items = db.relationship('Item', backref='box', lazy=True, cascade="all, delete-orphan")
    histories = db.relationship('History', backref='box', lazy=True, cascade="all, delete-orphan")
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'description': self.description,  # Include description in the JSON output
            'is_open': self.is_open,
            'created_at': self.created_at.isoformat()
        }

# ---------------------
# Item Model
# ---------------------
class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    box_id = db.Column(db.Integer, db.ForeignKey('box.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    added_at = db.Column(db.DateTime, default=datetime.utcnow)
    image_path = db.Column(db.String(255), nullable=True)
    # description = db.Column(db.String(255), nullable=True)
    
    histories = db.relationship('History', backref='item', lazy=True, cascade="all, delete-orphan")
    
    def to_dict(self):
        return {
            'id': self.id,
            'box_id': self.box_id,
            'name': self.name,
            'added_at': self.added_at.isoformat(), 
            'image_path': self.image_path,       
        }

# ---------------------
# History Model
# ---------------------
class History(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    box_id = db.Column(db.Integer, db.ForeignKey('box.id'), nullable=True)  
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=True)  
    action_type = db.Column(db.String(20), nullable=False)  # e.g. 'Item Aadded', 'Item Removed', 'Box Opened', 'Box Closed'
    action_time = db.Column(db.DateTime, default=datetime.utcnow)
    details = db.Column(db.String(255), nullable=True)  
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'box_id': self.box_id,
            'item_id': self.item_id,
            'action_type': self.action_type,
            'action_time': self.action_time.isoformat(),
            'details': self.details
        }

class AccessStatus(Enum):
    PENDING ='pending'
    ACCEPTED = 'accepted'
    REJECTED = 'rejected'

class BoxAccess(db.Model):
    __tablename__ = 'box_access'
    id            = db.Column(db.Integer, primary_key=True)
    box_id        = db.Column(db.Integer, db.ForeignKey('box.id'), nullable=False)
    user_id       = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    requested_by  = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    status        = db.Column(db.Enum(AccessStatus), default=AccessStatus.PENDING, nullable=False)
    requested_at  = db.Column(db.DateTime, default=datetime.utcnow)
    responded_at  = db.Column(db.DateTime, nullable=True)

    
    box          = db.relationship('Box', backref=db.backref('accesses', lazy=True, cascade="all, delete-orphan"))
    user         = db.relationship('User', foreign_keys=[user_id], backref=db.backref('box_access_requests', lazy=True))
    requester    = db.relationship('User', foreign_keys=[requested_by])

    def to_dict(self):
        return {
            "id": self.id,
            "box_id": self.box_id,
            "user_id": self.user_id,
            "requested_by": self.requested_by,
            "status": self.status.value,
            "requested_at": self.requested_at.isoformat(),
            "responded_at": self.responded_at and self.responded_at.isoformat()
        }



#----------------
# EndPoints
#----------------

@app.route('/me', methods=['GET'])
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
    app.logger.error(f"[JWT ERROR] Missing token: {error_string}")
    return jsonify({"error": "Missing Authorization token", "detail": error_string}), 401

# Handle invalid token (malformed, wrong signature, etc.)
@jwt.invalid_token_loader
def invalid_token_callback(error_string):
    app.logger.error(f"[JWT ERROR] Invalid token: {error_string}")
    return jsonify({"error": "Invalid token", "detail": error_string}), 401

# Handle expired token
@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    user_id = jwt_payload.get('sub', 'unknown')
    app.logger.error(f"[JWT ERROR] Expired token for user ID: {user_id}")
    return jsonify({"error": "Token expired"}), 401

# Handle fresh token required (if you use @fresh_jwt_required)
@jwt.needs_fresh_token_loader
def needs_fresh_token_callback(jwt_header, jwt_payload):
    app.logger.error("[JWT ERROR] Fresh token required")
    return jsonify({"error": "Fresh token required"}), 401

# Handle revoked token (if you use token revoking)
@jwt.revoked_token_loader
def revoked_token_callback(jwt_header, jwt_payload):
    app.logger.error("[JWT ERROR] Token has been revoked")
    return jsonify({"error": "Token has been revoked"}), 401

def is_authorized(user_id: int, box_id: int) -> bool:
    # owner?
    if Box.query.filter_by(id=box_id, user_id=user_id).first():
        return True
    # accepted collaborator?
    access = BoxAccess.query.filter_by(
        box_id=box_id,
        user_id=user_id,
        status=AccessStatus.ACCEPTED
    ).first()
    return access is not None

# function to add the request to db (use in form)
@app.route('/api/box/request_access', methods=['POST'])
def request_access():
    data = request.get_json()
    box_id        = data.get('box_id')
    invitee_email = data.get('invitee_email')
    requested_by  = data.get('requested_by')   # owner’s user_id

    # 1) Basic validation
    if not all([box_id, invitee_email, requested_by]):
        return jsonify({"error": "box_id, invitee_email and requested_by are required"}), 400

    box = Box.query.get(box_id)
    if not box or box.user_id != requested_by:
        return jsonify({"error": "Invalid box or permission"}), 403

    # 2) Look up the invitee by email
    invitee = User.query.filter_by(email=invitee_email).first()
    if not invitee:
        return jsonify({"error": "No user with that email"}), 404

    # 3) Avoid duplicate invitations
    existing = BoxAccess.query.filter_by(box_id=box_id, user_id=invitee.id).first()
    if existing:
        return jsonify({"error": "You have already invited that user"}), 400

    # 4) Create the request
    req = BoxAccess(
        box_id       = box_id,
        user_id      = invitee.id,
        requested_by = requested_by
    )
    db.session.add(req)
    db.session.commit()
    return jsonify(req.to_dict()), 201

# request sent by owner 
@app.route('/api/box/requests_sent', methods=['GET'])
def requests_sent():
    owner_id = request.args.get('owner_id', type=int)
    # join through boxes the owner owns
    requests = BoxAccess.query.join(Box).filter(
        Box.user_id == owner_id,
        BoxAccess.status == AccessStatus.PENDING
    ).all()
    return jsonify([r.to_dict() for r in requests]), 200
#request received
@app.route('/api/box/requests_received', methods=['GET'])
def requests_received():
    user_id = request.args.get('user_id', type=int)
    reqs = BoxAccess.query.filter_by(user_id=user_id, status=AccessStatus.PENDING).all()
    return jsonify([r.to_dict() for r in reqs]), 200
#functio to accept or deny the request 
@app.route('/api/box/respond_request', methods=['POST'])
def respond_request():
    data       = request.get_json()
    req_id     = data.get('request_id')
    accept     = data.get('accept')   # boolean

    req = BoxAccess.query.get(req_id)
    if not req or req.status != AccessStatus.PENDING:
        return jsonify({"error": "Invalid request"}), 404

    # only the invited user can respond
    if req.user_id != data.get('user_id'):
        return jsonify({"error": "Not permitted"}), 403

    req.status = AccessStatus.ACCEPTED if accept else AccessStatus.REJECTED
    req.responded_at = datetime.utcnow()
    db.session.commit()
    return jsonify(req.to_dict()), 200

@app.route('/api/shared_boxes', methods=['GET'])
def shared_boxes():
    uid = request.args.get('user_id', type=int)
    # owned = Box.query.filter_by(user_id=uid)
    # accepted
    shared = Box.query.join(BoxAccess).filter(
        BoxAccess.user_id == uid,
        BoxAccess.status == AccessStatus.ACCEPTED
    )
    # boxes = owned.union(shared).all()
    return jsonify([b.to_dict() for b in shared]), 200





@app.route('/register', methods=['POST'])
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


@app.route('/login', methods=['POST'])
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

@app.route('/api/boxes', methods=['GET'])
def get_boxes():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id parameter'}), 400
    
    boxes = Box.query.filter_by(user_id=user_id).all()
    return jsonify([box.to_dict() for box in boxes]), 200

@app.route('/api/add_box', methods=['POST'])
def add_box():
    data = request.get_json()
    if not data or not all(k in data for k in ('user_id', 'name')):
        return jsonify({'error': 'Missing required fields: user_id and name'}), 400
    
    user_id = data['user_id']
    name = data['name']
    description = data.get('description', '')  
    
    new_box = Box(user_id=user_id, name=name, description=description)
    db.session.add(new_box)
    db.session.commit()
    
    return jsonify(new_box.to_dict()), 201

@app.route('/api/items', methods=['GET'])
def get_items():
    box_id = request.args.get('box_id')
    if not box_id:
        return jsonify({'error': 'Missing box_id parameter'}), 400
    items = Item.query.filter_by(box_id=box_id).all()
    return jsonify([item.to_dict() for item in items]), 200


@app.route('/api/add_item', methods=['POST'])
def add_item():
    name = request.form.get('name')
    box_id = request.form.get('box_id')
    user_id = request.form.get('user_id')
    image = request.files.get('image')

    if not name or not box_id:
        return jsonify({'error': 'Missing required fields'}), 400

    box = Box.query.get(box_id)
    if not box:
        return jsonify({'error': 'Box not found'}), 404
    
    if not is_authorized(user_id, box_id):
        return jsonify({"error": "Not authorized"}), 403

    image_path = None
    if image:
        ext = os.path.splitext(image.filename)[1]
        filename = f"{uuid.uuid4().hex}{ext}"
        image_folder = os.path.join(basedir, 'uploads')
        os.makedirs(image_folder, exist_ok=True)
        image.save(os.path.join(image_folder, filename))
        image_path = f'/uploads/{filename}'

    new_item = Item(box_id=box_id, name=name, image_path=image_path)
    db.session.add(new_item)
    db.session.commit()

    history = History(
        user_id=user_id,
        box_id=box_id,
        item_id=new_item.id,
        action_type='Item Added',
        details=f'Added item {name}'
    )
    db.session.add(history)
    db.session.commit()

    return jsonify(new_item.to_dict()), 201


@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(os.path.join(basedir, 'uploads'), filename)

@app.route('/api/remove_item/<int:item_id>', methods=['DELETE'])
def remove_item(item_id):
    item = Item.query.get(item_id)
    if not item:
        return jsonify({'error': 'Item not found'}), 404

    box = Box.query.get(item.box_id)
    if not box:
        return jsonify({'error': 'Box not found'}), 404
    
    # if not is_authorized(user_id, box_id):
    #     return jsonify({"error": "Not authorized"}), 403

    history = History(
        user_id=box.user_id,
        box_id=box.id,
        item_id=item.id,
        action_type='Item Removed',
        details=f'Removed item {item.name}'
    )
    db.session.delete(item)
    db.session.add(history)
    db.session.commit()
    
    return jsonify({'message': 'Item removed successfully.'}), 200

@app.route('/api/history/<int:box_id>', methods=['GET'])
def get_history(box_id):
    user_id = request.args.get('user_id', type=int)
    item_id = request.args.get('item_id', type=int)

    # Base query: required box_id from path
    query = History.query.filter_by(box_id=box_id)

    # Apply extra filters if provided
    if user_id is not None:
        query = query.filter_by(user_id=user_id)
    if item_id is not None:
        query = query.filter_by(item_id=item_id)

    # Order newest first
    histories = query.order_by(History.action_time.desc()).all()

    return jsonify([h.to_dict() for h in histories]), 200


@app.route('/api/boxes_items_grouped', methods=['GET'])
def get_boxes_items_grouped():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({'error': 'Missing user_id parameter'}), 400

    # 1) Owned boxes
    owned = Box.query.filter_by(user_id=user_id).all()

    # 2) Shared & accepted boxes
    shared = (
        Box.query
           .join(BoxAccess, BoxAccess.box_id == Box.id)
           .filter(
             BoxAccess.user_id == user_id,
             BoxAccess.status  == AccessStatus.ACCEPTED
           )
           .all()
    )

    # 3) Merge and dedupe
    final_boxes = {b.id: b for b in owned}
    for b in shared:
        final_boxes.setdefault(b.id, b)

    # 4) Group items
    grouped = []
    for box in final_boxes.values():
        items = [it.to_dict() for it in box.items]
        if not items:
            continue
        grouped.append({
            'box_id':   box.id,
            'box_name': box.name,
            'items':    items
        })

    return jsonify(grouped), 200

@app.route('/api/box/collaborators', methods=['GET'])
def collaborators():
    box_id = request.args.get('box_id', type=int)
    users = (
      db.session.query(User)
        .join(BoxAccess, BoxAccess.user_id == User.id)
        .filter(BoxAccess.box_id == box_id,
                BoxAccess.status == AccessStatus.ACCEPTED)
        .all()
    )
    return jsonify([u.to_dict() for u in users]), 200


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True,host='0.0.0.0', port=5000)
