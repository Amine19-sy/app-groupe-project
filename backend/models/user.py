from extensions import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.Text, nullable=False)
    
    # Relationships
    boxes = db.relationship('Box', backref='owner', lazy=True, cascade="all, delete-orphan")
    histories = db.relationship('History', backref='user', lazy=True, cascade="all, delete-orphan")
    device_tokens = db.relationship('DeviceToken',back_populates='user',lazy='dynamic',cascade='all, delete-orphan')

    
    def to_dict(self):
        return {'id': self.id, 'username': self.username, 'email': self.email}