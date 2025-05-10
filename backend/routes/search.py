from datetime import datetime
from flask import Blueprint, request, jsonify
from models.box import Box
from models.history import History
from models.box_access import AccessStatus, BoxAccess
from models.user import User

search_bp = Blueprint('search', __name__)

@search_bp.route('/api/user_collaborators', methods=['GET'])
def user_collaborators():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({'error': 'Missing user_id parameter'}), 400

    # 1) Boxes the user owns:
    owned_ids = [b.id for b in Box.query.filter_by(user_id=user_id).all()]

    # 2) Everyone they’ve granted access to:
    accesses = BoxAccess.query.filter(
        BoxAccess.box_id.in_(owned_ids),
        BoxAccess.status == AccessStatus.ACCEPTED
    ).all()
    collaborator_ids = {user_id} | {a.user_id for a in accesses}

    users = User.query.filter(User.id.in_(collaborator_ids)).all()
    return jsonify([{'id': u.id, 'name': u.username} for u in users]), 200

@search_bp.route('/api/boxes_items_grouped', methods=['GET'])
def get_boxes_items_grouped():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({'error': 'Missing user_id parameter'}), 400

    # parse optional filters
    date_from_str = request.args.get('date_from')
    date_to_str   = request.args.get('date_to')
    added_by      = request.args.get('added_by', type=int)

    date_from = datetime.fromisoformat(date_from_str) if date_from_str else None
    date_to   = datetime.fromisoformat(date_to_str)   if date_to_str   else datetime.utcnow()

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

    # 4) Group items with filters
    grouped = []
    for box in final_boxes.values():
        filtered_items = []
        for it in box.items:
            # date filter
            if date_from and it.added_at < date_from:
                continue
            if date_to   and it.added_at > date_to:
                continue

            # "added by" filter
            if added_by is not None:
                exists = (
                  History.query
                         .filter_by(item_id=it.id,
                                    user_id=added_by,
                                    action_type='Item Added')
                         .first()
                )
                if not exists:
                    continue

            filtered_items.append(it.to_dict())

        if not filtered_items:
            continue

        grouped.append({
            'box_id':   box.id,
            'box_name': box.name,
            'items':    filtered_items
        })

    return jsonify(grouped), 200
