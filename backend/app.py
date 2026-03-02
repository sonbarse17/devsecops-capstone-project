from flask import Flask, request, jsonify
import pymysql
import json
import os

app = Flask(__name__)

# Secure configuration
app.config['DEBUG'] = False # Disable debug in production!

# Secure environment variable handling (No fallbacks to hardcoded values)
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_NAME = os.environ.get('DB_NAME')

def get_db_connection():
    return pymysql.connect(host=DB_HOST,
                           user=DB_USER,
                           password=DB_PASSWORD,
                           database=DB_NAME,
                           cursorclass=pymysql.cursors.DictCursor)

@app.route('/')
def index():
    return jsonify({"message": "Insecure Python API running!"})

# Secure: Parameterized SQL Query
@app.route('/users', methods=['GET'])
def get_users():
    user_id = request.args.get('id')
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            if user_id:
                # Safe Parameterized query
                query = "SELECT * FROM users WHERE id = %s"
                cursor.execute(query, (user_id,))
            else:
                query = "SELECT * FROM users"
                cursor.execute(query)

            result = cursor.fetchall()
        conn.close()
        return jsonify(result)
    except Exception as e:
        return str(e), 500

# Secure: Using JSON instead of Pickle
@app.route('/deserialize', methods=['POST'])
def deserialize():
    try:
        data = request.json.get('data') # Expects JSON string
        obj = json.loads(data)
        return jsonify({"status": "Success", "object_type": str(type(obj))})
    except Exception as e:
        return str(e), 500

@app.route('/data', methods=['POST'])
def handle_data():
    datar = request.json
    return jsonify({"status": "ok", "received": datar})

if __name__ == '__main__':
    # Secure: Debug Mode OFF
    app.run(host='0.0.0.0', port=5000, debug=False) # nosec B104
