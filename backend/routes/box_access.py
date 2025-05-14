from flask import Blueprint, request, jsonify
from extensions import db
from models.box import Box
from models.box_access import AccessStatus, BoxAccess
from models.user import User
from datetime import datetime
from services.notification_service import send_push_to_user


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
    owner = User.query.get(requested_by)

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
    result = send_push_to_user(
    user_id=invitee.id,
    title="New Collaboration request!",
    body=f"{owner.username} sent you a request to manage the box : {box.name}",
    )

    db.session.add(req)
    db.session.commit()
    return jsonify(req.to_dict()), 201

# request sent by owner 
@box_access_bp.route('/api/box/requests_sent', methods=['GET'])
def requests_sent():
    owner_id = request.args.get('owner_id', type=int)

    requests = (
        BoxAccess.query
          .join(Box)
          .join(User, User.id == BoxAccess.user_id)
          .filter(
            Box.user_id == owner_id,
            BoxAccess.status == AccessStatus.PENDING
          )
          .all()
    )

    payload = []
    for r in requests:
        d = r.to_dict()
        d['box_name'] = r.box.name
        d['invetee_name'] = r.user.username
        d['requester_name'] = ''  
        payload.append(d)

    return jsonify(payload), 200

@box_access_bp.route('/api/box/requests_received', methods=['GET'])
def requests_received():
    user_id = request.args.get('user_id', type=int)

    reqs = BoxAccess.query \
        .join(Box, Box.id == BoxAccess.box_id) \
        .join(User, User.id == BoxAccess.requested_by) \
        .filter(BoxAccess.user_id == user_id, BoxAccess.status == AccessStatus.PENDING) \
        .all()

    result = []
    for r in reqs:
        data = r.to_dict()
        data['box_name'] = r.box.name
        data['requester_name'] = r.requester.username
        data['invetee_name'] = ''
        result.append(data)

    return jsonify(result), 200


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
    owner = User.query.get(req.requested_by)
    invitee = User.query.get(req.user_id)
    box = Box.query.get(req.box_id)

    decision = "accepted" if accept else "denied"
    title = f"Your request was {decision} !"
    body = f"{invitee.username} has {decision} your request to manage the box: {box.name}"

    result = send_push_to_user(
        user_id=req.requested_by,
        title=title,
        body=body,
    )
    return jsonify(req.to_dict()), 200
