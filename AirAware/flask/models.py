from app import db


class measurements_monthly(db.Model):

    grid_id = db.Column(db.Integer, db.ForeignKey('grid.grid_id'), primary_key=True)
    time = db.Column(db.DateTime, primary_key=True)
    parameter = db.Column(db.Integer, primary_key=True)
    c = db.Column(db.Float)

    def __repr__(self):
        return '<id {} at {}>'.format(self.grid_id, self.time)


class grid(db.Model):

    grid_id = db.Column(db.Integer, primary_key=True)
    longitude = db.Column(db.Float)
    latitude = db.Column(db.Float)
    measurements = db.relationship("measurements_monthly", backref="grid", lazy=True)

    def __repr__(self):
        return '<grid id {}>'.format(self.grid_id)
