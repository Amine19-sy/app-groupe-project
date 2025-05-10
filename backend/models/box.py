from extensions import db
from datetime import datetime

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