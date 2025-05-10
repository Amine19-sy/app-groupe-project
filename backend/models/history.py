from extensions import db
from datetime import datetime

class History(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    box_id = db.Column(db.Integer, db.ForeignKey('box.id'), nullable=True)  
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=True)  
    action_type = db.Column(db.String(20), nullable=False)  # e.g. 'Item Aadded', 'Item Removed', 'Box Opened', 'Box Closed'
    action_time = db.Column(db.DateTime, default=datetime.utcnow)
    details = db.Column(db.String(255), nullable=True)  
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'box_id': self.box_id,
            'item_id': self.item_id,
            'action_type': self.action_type,
            'action_time': self.action_time.isoformat(),
            'details': self.details
        }