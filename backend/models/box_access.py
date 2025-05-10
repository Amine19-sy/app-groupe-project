from extensions import db
from datetime import datetime
from enum import Enum

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