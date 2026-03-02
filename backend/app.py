from flask import Flask, request, jsonify
import pymysql
import os
import pickle
import base64

app = Flask(__name__)

# Insecure configuration
app.config['DEBUG'] = True # Do not use debug mode in prod!

# Hardcoded environment mapping or fallbacks (Insecure)
DB_HOST = os.environ.get('DB_HOST', 'database')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'password123')
DB_NAME = os.environ.get('DB_NAME', 'insecure_db')

def get_db_connection():
    return pymysql.connect(host=DB_HOST,
                           user=DB_USER,
                           password=DB_PASSWORD,
                           database=DB_NAME,
                           cursorclass=pymysql.cursors.DictCursor)

@app.route('/')
def index():
    return jsonify({"message": "Insecure Python API running!"})

# Insecure: SQL Injection Vulnerability
@app.route('/users', methods=['GET'])
def get_users():
    user_id = request.args.get('id')
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            if user_id:
                # Vulnerable to SQLi
                query = f"SELECT * FROM users WHERE id = {user_id}"
            else:
                query = "SELECT * FROM users"
            
            cursor.execute(query)
            result = cursor.fetchall()
        conn.close()
        return jsonify(result)
    except Exception as e:
        return str(e), 500

# Insecure Deserialization Vulnerability
@app.route('/deserialize', methods=['POST'])
def deserialize():
    try:
        data = request.json.get('data') # Expects base64 encoded pickle dump
        obj = pickle.loads(base64.b64decode(data))
        return jsonify({"status": "Success", "object_type": str(type(obj))})
    except Exception as e:
        return str(e), 500

@app.route('/data', methods=['POST'])
def handle_data():
    datar = request.json
    return jsonify({"status": "ok", "received": datar})

if __name__ == '__main__':
    # Insecure: Binding to all network interfaces and Debug Mode ON
    app.run(host='0.0.0.0', port=5000, debug=True)
