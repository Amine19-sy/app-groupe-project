from flask import Blueprint, request, jsonify
from extensions import db
from models.box import Box
from models.box_access import AccessStatus, BoxAccess
from models.user import User
from datetime import datetime

box_access_bp = Blueprint('box_access', __name__)

# function to add the request to db (use in form)
@box_access_bp.route('/api/box/request_access', methods=['POST'])
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
@box_access_bp.route('/api/box/requests_sent', methods=['GET'])
def requests_sent():
    owner_id = request.args.get('owner_id', type=int)
    # join through boxes the owner owns
    requests = BoxAccess.query.join(Box).filter(
        Box.user_id == owner_id,
        BoxAccess.status == AccessStatus.PENDING
    ).all()
    return jsonify([r.to_dict() for r in requests]), 200
#request received
@box_access_bp.route('/api/box/requests_received', methods=['GET'])
def requests_received():
    user_id = request.args.get('user_id', type=int)
    reqs = BoxAccess.query.filter_by(user_id=user_id, status=AccessStatus.PENDING).all()
    return jsonify([r.to_dict() for r in reqs]), 200
#functio to accept or deny the request 
@box_access_bp.route('/api/box/respond_request', methods=['POST'])
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
