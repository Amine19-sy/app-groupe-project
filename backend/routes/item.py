import uuid
from flask import Blueprint, request, jsonify
from extensions import db
from models.box import Box
from models.item import Item
from models.history import History
import os
from flask import send_from_directory
from models.box_access import AccessStatus, BoxAccess
from config import basedir

item_bp = Blueprint('item', __name__)

@item_bp.route('/api/items', methods=['GET'])
def get_items():
    box_id = request.args.get('box_id')
    if not box_id:
        return jsonify({'error': 'Missing box_id parameter'}), 400
    items = Item.query.filter_by(box_id=box_id).all()
    return jsonify([item.to_dict() for item in items]), 200


@item_bp.route('/api/add_item', methods=['POST'])
def add_item():
    name = request.form.get('name')
    box_id = request.form.get('box_id')
    user_id = request.form.get('user_id')
    description = request.form.get('description')
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

    new_item = Item(box_id=box_id, name=name, image_path=image_path,description=description)
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


@item_bp.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(os.path.join(basedir, 'uploads'), filename)

@item_bp.route('/api/remove_item/<int:item_id>', methods=['DELETE'])
def remove_item(item_id):
    item = Item.query.get(item_id)
    if not item:
        return jsonify({'error': 'Item not found'}), 404

    box = Box.query.get(item.box_id)
    if not box:
        return jsonify({'error': 'Box not found'}), 404
    
    # if not is_authorized(user_id, box_id):
    #     return jsonify({"error": "Not authorized"}), 403

    if item.image_path:
        # item.image_path is like '/uploads/filename.jpg'
        filename = os.path.basename(item.image_path)  # extract 'filename.jpg'
        image_full_path = os.path.join(basedir, 'uploads', filename)
        if os.path.exists(image_full_path):
            try:
                os.remove(image_full_path)
            except Exception as e:
                print(f"Error deleting image file: {e}")

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