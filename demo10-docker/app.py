from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
import json

#json 파일 읽기
with open('terraform_outputs.json', 'r') as f:
    outputs = json.load(f)

# db_endpoint의 value 값을 추출
db_endpoint = outputs['db_endpoint']

# MySQL 연결 URI 생성
username = outputs['db_user']  # MySQL 사용자 이름
password = outputs['db_password']  # MySQL 비밀번호
database_name = outputs['db_name']  # MySQL 데이터베이스 이름

# MySQL URI 포맷
mysql_uri = f'mysql+mysqlconnector://{username}:{password}@{db_endpoint}/{database_name}'


app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = mysql_uri #db 연결
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)

    def __repr__(self):
        return f'<Item {self.name}>'

@app.before_first_request
def create_tables():
    db.create_all()

#healthCheck
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"})


#CREATE
@app.route('/items', methods=['POST'])
def add_item():
    data = request.json
    new_item = Item(name=data['name'])
    try:
        db.session.add(new_item)
        db.session.commit()
        return jsonify({'id': new_item.id, 'name': new_item.name}), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({'error': 'Item already exists'}), 400

#READ
@app.route('/items', methods=['GET'])
def get_items():
    items = Item.query.all()
    return jsonify([{'id': item.id, 'name': item.name} for item in items])

#UPDATE
@app.route('/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    data = request.json
    item = Item.query.get_or_404(item_id) #없으면 404 
    item.name = data['name']
    db.session.commit()
    return jsonify({'id': item.id, 'name': item.name})

#DELETE
@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    item = Item.query.get_or_404(item_id)
    db.session.delete(item)
    db.session.commit()
    return jsonify({'message': 'Item deleted'})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

