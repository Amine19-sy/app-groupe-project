from flask import Blueprint, request, jsonify
from extensions import db
from models.box import Box
from models.box_access import AccessStatus, BoxAccess
from models.user import User



box_bp = Blueprint('box', __name__)

@box_bp.route('/api/add_box', methods=['POST'])
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

@box_bp.route('/api/boxes', methods=['GET'])
def get_boxes():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id parameter'}), 400
    
    boxes = Box.query.filter_by(user_id=user_id).all()
    return jsonify([box.to_dict() for box in boxes]), 200

@box_bp.route('/api/shared_boxes', methods=['GET'])
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

@box_bp.route('/api/box/box_collaborators', methods=['GET'])
def box_collaborators():
    box_id = request.args.get('box_id', type=int)
    users = (
      db.session.query(User)
        .join(BoxAccess, BoxAccess.user_id == User.id)
        .filter(BoxAccess.box_id == box_id,
                BoxAccess.status == AccessStatus.ACCEPTED)
        .all()
    )
    return jsonify([u.to_dict() for u in users]), 200