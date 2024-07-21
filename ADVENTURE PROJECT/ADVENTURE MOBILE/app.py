#from xml.dom import UserDataHandler
import base64
import io
from flask import Flask, Response, request, jsonify, send_file
import psycopg2
from datetime import datetime

app = Flask(__name__)

ad_content = {}
def get_db_connection():
    conn = psycopg2.connect(
        database="miniproj",
        user="postgres",
        host='localhost',
        password="123456",
        port=5432
    )
    return conn

#SIGN UP
def create_user(username, password, email, first_name, last_name):
  """Creates a new user in the database."""
  conn = get_db_connection()
  cursor = conn.cursor()

  # Hash the password before storing it
  #hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

  try:
    # SQL query to insert user data
    sql = """
        INSERT INTO users (username, password, email, first_name, last_name)
        VALUES (%s, %s, %s, %s, %s)
    """

    # Execute the query with user data
    cursor.execute(sql, (username,password, email, first_name, last_name))
    conn.commit()

    print(f"User '{username}' created successfully!")

    # Consider returning the user ID if needed

  except Exception as e:
    print(f"Error creating user: {e}")
    conn.rollback()  # Rollback changes on error


@app.route("/signup", methods=["POST"])
def register_user():
  """Handles POST requests for user signup."""
  # Get data from the request body
  data = request.get_json()
  username = data.get("username")
  password = data.get("password")
  email = data.get("email")
  first_name = data.get("first_name")
  last_name = data.get("last_name")

  # Validation
  if not username or not password or not email or not first_name or not last_name:
    return jsonify({"error": "Missing required fields"}), 400

  try:
    create_user(username, password, email, first_name, last_name)
    return jsonify({"message": "Registration successful!"}), 201
  except Exception as e:
    print(f"Error during user registration: {e}")
    return jsonify({"error": "Registration failed"}), 500


#LOGIN
@app.route('/login', methods=['POST'])
def login_user():
    # Get user data from the request body (assuming JSON format)
    data = request.get_json()

    username = data.get('username')
    password = data.get('password')

    # Validate input data (optional)

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Check if username exists
        cursor.execute("""
            SELECT id FROM users WHERE username = %s
        """, (username,))
        user_id = cursor.fetchone()

        if user_id:  # User found
            # Validate password (replace with your password hashing logic)
            # Assuming password is stored at index 2
            cursor.execute("""
                SELECT id FROM users WHERE username = %s AND password = %s
            """, (username, password))
            user_id = cursor.fetchone()
            print(f"Retrieved user ID: {user_id}")  # Debug print statement
            if user_id:
                return jsonify({'message': 'Login successful!', 'user_id': user_id[0]}), 200
            else:
                return jsonify({'message': 'Invalid password'}), 401  # Unauthorized
        else:
            return jsonify({'message': 'Username not found'}), 404  # Not Found

    except (Exception, psycopg2.Error) as error:
        print("Error while logging in:", error)
        return jsonify({'message': 'Login failed!'}), 400  # Bad Request
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
@app.route('/screens', methods=['GET'])
def get_screens():
    try:
        owner_id = request.args.get('owner_id')
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT screen_name FROM screens WHERE owner_id = %s", (owner_id,))
        screen_names = cursor.fetchall()
        cursor.close()
        conn.close()
        screen_names = [name[0] for name in screen_names]  # Extract screen names from tuples
        return jsonify({'screen_names': screen_names}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/getscreenid', methods=['GET'])
def get_screen_id():
    try:
        owner_id = request.args.get('owner_id')
        screen_name = request.args.get('screen_name')
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT screen_id FROM screens WHERE owner_id = %s AND screen_name = %s", (owner_id, screen_name))
        screen_id = cursor.fetchone()
        cursor.close()
        conn.close()
        if screen_id:
            return jsonify({'screen_id': screen_id[0]}), 200
        else:
            return jsonify({'error': 'Screen not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500



@app.route('/get-ad/<screenid>', methods=['GET'])
def get_ad(screenid):
    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        if not connection:
            return jsonify({'error': 'Failed to connect to database'}), 500

        # Get current date and time
        current_datetime = datetime.now()

        # Prepare SQL query to select video_path based on ad_schedule and ads tables
        sql = """
            SELECT ads.file_name
            FROM ads
            JOIN ad_schedule ON ads.ad_id = ad_schedule.ad_id
            WHERE ad_schedule.screen_id = %s
            AND ad_schedule.schedule_date = %s
            AND ad_schedule.start_time <= %s
            AND ad_schedule.end_time >= %s;
        """
        cursor.execute(sql, (screenid, current_datetime.date(), current_datetime.time(), current_datetime.time()))

        row = cursor.fetchone()
        if not row:
            return jsonify({'error': 'No ad found for the specified screen and time'}), 404

        file_name = row[0]

        connection.close()
        return jsonify({'videoUrl': file_name}), 200

    except Exception as e:
        print("Error fetching ad:", e)
        return jsonify({'error': 'Failed to fetch ad'}), 500






    








if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
