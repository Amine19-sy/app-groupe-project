from extensions import db
from datetime import datetime

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    box_id = db.Column(db.Integer, db.ForeignKey('box.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    added_at = db.Column(db.DateTime, default=datetime.utcnow)
    image_path = db.Column(db.String(255), nullable=True)
    description = db.Column(db.String(255), nullable=True)
    
    histories = db.relationship('History', backref='item', lazy=True, cascade="all, delete-orphan")
    
    def to_dict(self):
        return {
            'id': self.id,
            'box_id': self.box_id,
            'name': self.name,
            'added_at': self.added_at.isoformat(), 
            'image_path': self.image_path,       
            'description':self.description
        }