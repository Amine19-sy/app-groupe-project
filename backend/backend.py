from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os
from flask_cors import CORS
from datetime import datetime
import uuid
from flask import send_from_directory
from sqlalchemy import or_


app = Flask(__name__)
CORS(app)
# Configure the SQLite database location
basedir = os.path.abspath(os.path.dirname(__file__))
db_path = os.path.join(basedir, 'db.sqlite')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + db_path
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# ---------------------
# User Modelp0
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

#----------------
# EndPoints
#----------------



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
    print("seccessfully")
    return jsonify({"user": new_user.to_dict()}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not all(k in data for k in ("username", "password")):
        return jsonify({"error": "Missing username or password"}), 400

    username = data['username']
    password = data['password']

    user = User.query.filter_by(username=username).first()
    if user and check_password_hash(user.password_hash, password):
       
        return jsonify({"user": user.to_dict()}), 200
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

# @app.route('/api/add_item', methods=['POST'])
# def add_item():
#     data = request.get_json()
#     required_fields = ['box_id', 'name']
#     if not data or not all(field in data for field in required_fields):
#         return jsonify({'error': 'Missing required fields: box_id and name'}), 400

#     box_id = data['box_id']
#     name = data['name']
#     # quantity = data.get('quantity', 1)
    
    
#     box = Box.query.get(box_id)
#     if not box:
#         return jsonify({'error': 'Box not found'}), 404

#     new_item = Item(box_id=box_id, name=name)
#     db.session.add(new_item)
#     db.session.commit()  
    
#     history = History(
#         user_id=box.user_id,
#         box_id=box_id,
#         item_id=new_item.id,
#         action_type='Item Added',
#         details=f'Added item {name}'
#     )
#     db.session.add(history)
#     db.session.commit()
    
#     return jsonify(new_item.to_dict()), 201


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
    """
    Fetch history for a specific box, optionally filtered by user or item.
    URL param:
      - box_id : int
    Query params:
      - user_id : int (optional)
      - item_id : int (optional)
    """
    # Optional filters
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




if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        # Item.query.delete()
        # db.session.commit()
    app.run(debug=True,host='0.0.0.0', port=5000)
