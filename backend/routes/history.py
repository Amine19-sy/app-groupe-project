from flask import Blueprint, jsonify, request
from models.history import History



history_bp = Blueprint('history', __name__)

@history_bp.route('/api/history/<int:box_id>', methods=['GET'])
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