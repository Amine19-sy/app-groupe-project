from extensions import db
from datetime import datetime

class DeviceToken(db.Model):
    __tablename__ = 'device_tokens'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'), nullable=False)
    token = db.Column(db.String(255), unique=True, nullable=False)
    device_info = db.Column(db.String(255))         # e.g. “Pixel 4a / Android 12”
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_seen = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User', back_populates='device_tokens')
