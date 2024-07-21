from flask import Flask, request, jsonify
from flask import render_template
import datetime
import psycopg2
app = Flask(__name__)

def get_db_connection():
  conn = psycopg2.connect(database="miniproj",
                          user="postgres",
                          host='localhost',
                          password="123456",
                          port=5432)
  return conn

#SIGNUP
def create_user(username, password, email, first_name, last_name):
  """Creates a new user in the database."""
  conn = get_db_connection()
  cursor = conn.cursor()

  try:
    sql = """
        INSERT INTO users (username, password, email, first_name, last_name)
        VALUES (%s, %s, %s, %s, %s)
    """

    cursor.execute(sql, (username,password, email, first_name, last_name))
    conn.commit()

    print(f"User '{username}' created successfully!")

  except Exception as e:
    print(f"Error creating user: {e}")
    conn.rollback()

  
@app.route("/signup", methods=["POST"])
def register_user():
  """Handles POST requests for user signup."""

  data = request.get_json()
  username = data.get("username")
  password = data.get("password")
  email = data.get("email")
  first_name = data.get("first_name")
  last_name = data.get("last_name")

  if not username or not password or not email or not first_name or not last_name:
    return jsonify({"error": "Missing required fields"}), 400

  try:
    create_user(username, password, email, first_name, last_name)
    return jsonify({"message": "Registration successful!"}), 201
  except Exception as e:
    print(f"Error during user registration: {e}")
    return jsonify({"error": "Registration failed"}), 500

# LOGIN
@app.route('/login', methods=['POST'])
def login_user():
  data = request.get_json()
  username = data.get('username')
  password = data.get('password')

  conn = get_db_connection()
  cursor = conn.cursor()

  try:
    cursor.execute("""
        SELECT id FROM users WHERE username = %s
    """, (username,))
    user_id = cursor.fetchone()

    if user_id:  # User found

      cursor.execute("""
          SELECT id FROM users WHERE username = %s AND password = %s
      """, (username, password))
      user_id = cursor.fetchone()
      print(f"Retrieved user ID: {user_id}") 
      if user_id:
        return jsonify({'message': 'Login successful!', 'user_id': user_id[0]}), 200
      else:
        return jsonify({'message': 'Invalid password'}), 401 
    else:
      return jsonify({'message': 'Username not found'}), 404  

  except (Exception, psycopg2.Error) as error:
    print("Error while logging in:", error)
    return jsonify({'message': 'Login failed!'}), 400 
  
# NEW SCREEN
@app.route('/newScreen', methods=['POST'])
def register_screen():
  """Handles POST requests for registering a new screen."""
  data = request.get_json()

  screen_name = data.get('screen_name')
  location = data.get('location')
  business_type = data.get('business_type')
  owner_id = data.get('user_id')
  footfall = data.get('footfall')  
  base_rate = data.get('base_rate')  
  peak_hour_multiplier = data.get('peak_hour_multiplier') 
  peak_hour_start = data.get('peak_hour_start') 
  peak_hour_end = data.get('peak_hour_end') 

  if not all([screen_name, location, business_type, owner_id, footfall, base_rate, peak_hour_multiplier]):
    return jsonify({'message': 'Missing required fields'}), 400

  try:
    footfall = int(footfall) 
    if footfall <= 0:
      return jsonify({'message': 'Footfall must be a positive integer'}), 400
  except ValueError:
    return jsonify({'message': 'Invalid footfall value (must be a number)'}), 400


  try:
    base_rate = float(base_rate) 
    if base_rate <= 0:
      return jsonify({'message': 'Base rate must be a positive number'}), 400
  except ValueError:
    return jsonify({'message': 'Invalid base rate value (must be a number)'}), 400

  try:
    peak_hour_multiplier = float(peak_hour_multiplier) 
    if peak_hour_multiplier <= 0:
      return jsonify({'message': 'Peak hour multiplier must be a positive number'}), 400
  except ValueError:
    return jsonify({'message': 'Invalid peak hour multiplier value (must be a number)'}), 400

  try:
    conn = get_db_connection()
    cursor = conn.cursor()

    # Modify the SQL query to include peak_hour_start and peak_hour_end
    sql = """
        INSERT INTO screens (screen_name, location, business_type, owner_id, footfall, base_rate, peak_hr_multiplier, peak_hour_start, peak_hour_end)
        VALUES (%s, UPPER(LEFT(%s, 1)) || LOWER(SUBSTRING(%s, 2)), UPPER(LEFT(%s, 1)) || LOWER(SUBSTRING(%s, 2)), %s, %s, %s, %s, %s, %s)
    """
    print(sql)
    # Handle potential absence of peak_hour_start and peak_hour_end in the request data
    if peak_hour_start is not None and peak_hour_end is not None:
      cursor.execute(sql, (screen_name, location, location, business_type, business_type, owner_id, footfall, base_rate, peak_hour_multiplier, peak_hour_start, peak_hour_end))
    else:
      # If peak hours are not provided, insert NULL values (adjust based on your database schema)
      cursor.execute(sql, (screen_name, location, location, business_type, business_type, owner_id, footfall, base_rate, peak_hour_multiplier, None, None))

    conn.commit()

    return jsonify({'message': 'Screen registration successful!'}), 201

  except (Exception, psycopg2.Error) as error:
    print("Error while registering screen:", error)
    conn.rollback()
    return jsonify({'message': 'Registration failed!'}), 400

@app.route("/locations", methods=["GET"])
def get_locations():
  try:
    cursor = get_db_connection().cursor()
    cursor.execute("SELECT DISTINCT location FROM screens")  # Get unique locations
    result = cursor.fetchall()

    locations = [row[0] for row in result]  # Extract locations from query results

    return jsonify(locations)

  except Exception as e:
    print(f"Error retrieving locations: {e}")
    return jsonify({"error": "Failed to retrieve locations"}), 500
        
@app.route('/screens', methods=['GET'])
def get_screens():
    try:
        location = request.args.get('location')
        business_type = request.args.get('business_type')

        sql = "SELECT screen_name FROM screens"
        params = []

        if location:
            sql += " WHERE location = %s"
            params.append(location)
        if business_type and business_type != 'All':  # Handle "All" case separately
            if params:
                sql += " AND"
            else:
                sql += " WHERE"
            sql += " business_type = %s"
            params.append(business_type)

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(sql, params)
        screen_names = cursor.fetchall()

        # Return a list of screen names instead of tuples
        screen_names = [name[0] for name in screen_names]
        return jsonify({'screen_names':screen_names}), 200
    except Exception as e:
        print(f"Error retrieving screens: {e}")
        return jsonify({'error': str(e)}), 500

@app.route("/business_type", methods=["GET"])
def get_business_types():
  try:
    cursor = get_db_connection().cursor()
    cursor.execute("SELECT DISTINCT business_type FROM screens")  # Get unique business types
    result = cursor.fetchall()

    business_types = [row[0] for row in result]  # Extract business types from query results

    return jsonify(business_types)

  except Exception as e:
    print(f"Error retrieving business types: {e}")
    return jsonify({"error": "Failed to retrieve business types"}), 500

  finally:
    cursor.close()
    get_db_connection().close()  # Close connection even on exceptions
   
@app.route("/regcount/<user_id>", methods=["GET"])
def get_screen_count(user_id):
  try:
    # Replace with your actual database connection logic (e.g., using SQLAlchemy, etc.)
    connection = get_db_connection()
    cursor = connection.cursor()
    print(user_id)
    # Modify the query to count screens based on user_id
    cursor.execute(f"SELECT COUNT(*) FROM screens WHERE owner_id = '{user_id}'")
    result = cursor.fetchone()

    if result:
      screen_count = result[0]  # Extract the count from the query result
      return jsonify({"count": screen_count})
    else:
      return jsonify({"count": 0})  # Return 0 if no screens found for the user

  except Exception as e:
    print(f"Error retrieving screen count for user {user_id}: {e}")
    return jsonify({"error": "Failed to retrieve screen count"}), 500

@app.route("/adsplayed/<user_id>", methods=["GET"])
def get_ads_seen_by(user_id):
  try:
    # Replace with your actual database connection logic (e.g., using SQLAlchemy, etc.)
    connection = get_db_connection()
    cursor = connection.cursor()
    print(user_id)
    # Modify the query to count screens based on user_id
    cursor.execute(f"SELECT COUNT(*) FROM ads WHERE advertiser_id = '{user_id}'")

    result = cursor.fetchone()

    if result:
      ad_count = result[0]  # Extract the count from the query result
      return jsonify({"count": ad_count})
    else:
      return jsonify({"count": 0})  # Return 0 if no screens found for the user

  except Exception as e:
    print(f"Error retrieving screen count for user {user_id}: {e}")
    return jsonify({"error": "Failed to retrieve screen count"}), 500

@app.route("/grossfootfallcount/<user_id>", methods=["GET"])
def get_gross_footfall_count(user_id):
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        print(user_id)
        # Modify the query to count screens based on user_id
        cursor.execute(f"SELECT sum(footfall) FROM screens WHERE owner_id = '{user_id}'")
        result = cursor.fetchone()

        if result:
            footfall_count = result[0]  # Extract the count from the query result
            return jsonify({"footfall": footfall_count})
        else:
            return jsonify({"footfall": 0})  # Return 0 if no screens found for the user

    except Exception as e:
        print(f"Error retrieving gross footfall count for user {user_id}: {e}")
        return jsonify({"error": "Failed to retrieve gross footfall count"}), 500

@app.route("/grosscollection/<int:user_id>", methods=["GET"])  # Ensure user_id is parsed as an integer
def get_grosscoll(user_id):
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        print(user_id)
        # Use parameterized query to prevent SQL injection
        cursor.execute("SELECT SUM(cost) FROM ad_schedule WHERE ad_id IN (SELECT ad_id FROM ads WHERE advertiser_id = %s)", (user_id,))
        result = cursor.fetchone()

        if result:
            collection = float(result[0]) if result[0] else 0.0  # Extract the sum from the query result and cast to float
            return jsonify({"collection": collection})
        else:
            return jsonify({"collection": 0.0})  # Return 0 if no collection found for the user

    except Exception as e:
        print(f"Error retrieving gross collection for user {user_id}: {e}")
        return jsonify({"error": "Failed to retrieve gross collection"}), 500

@app.route("/booked_slots", methods=["POST"])
def get_booked_slots():
    data = request.get_json()

    location = data.get("location")
    business_type = data.get("business_type")
    screen_names = data.get("screen_names")
    selected_date = data.get("date")

    conn = get_db_connection()
    cursor = conn.cursor()

    # Fetch screen ID for each selected screen name
    screen_ids = []
    for screen_name in screen_names:
        sql_screen_id = """
            SELECT screen_id FROM screens
            WHERE location = %s AND business_type = %s AND screen_name = %s
        """
        cursor.execute(sql_screen_id, (location, business_type, screen_name))
        screen_id = cursor.fetchone()
        if screen_id:
            screen_ids.append(screen_id)

    if screen_ids:
        # Fetch booked slots for each screen ID and selected date
        booked_slots = []
        for screen_id in screen_ids:
            sql_booked_slots = """
                SELECT start_time, end_time FROM ad_schedule 
                WHERE screen_id = %s AND schedule_date = %s
            """
            cursor.execute(sql_booked_slots, (screen_id, selected_date))
            slots = cursor.fetchall()
            booked_slots.extend(slots)

        # Convert the booked slots to a list of strings in the format "9-12" or "4-5"
        booked_slots_str = [f"{slot[0].strftime('%H:%M')}-{slot[1].strftime('%H:%M')}" for slot in booked_slots]
        return jsonify({"booked_slots": booked_slots_str}), 200
    else:
        return jsonify({"error": "Screens not found"}), 404

@app.route("/ad_schedule", methods=["POST"])
def schedule_ad():
    data = request.get_json()

    screens = data.get("screens", [])  # List of dictionaries containing screen info
    start_time = data.get("start_time")
    end_time = data.get("end_time")
    selected_date = data.get("date")  # Extracting selected date from the request
    ad_id = data.get("ad_id") 

    cost = 1
    conn = get_db_connection()
    cursor = conn.cursor()

    if not screens or not start_time or not end_time or not selected_date:
        return jsonify({"message": "Missing required data"}), 400

    for screen_data in screens:
        screen_name = screen_data.get("screen_name")
        if not screen_name:
            continue
        
        location = None
        business_type = None
        if len(screens) > 1:
            # Assuming location and business_type are in remaining dictionaries
            location = screens[1].get("location")
            business_type = screens[2].get("business_type")
            
        sql = """
            SELECT screen_id FROM screens WHERE screen_name = %s AND location = %s AND business_type = %s
        """
        cursor.execute(sql, (screen_name, location, business_type))
        screen_id = cursor.fetchone()
        if not screen_id:
            print(f"Screen not found: {screen_name}")
            continue  # Skip screens not found

        try:
            # Modify the SQL query to include selected_date
            sql = "INSERT INTO ad_schedule (ad_id,screen_id, start_time, end_time, schedule_date, cost) VALUES (%s,%s, %s, %s, %s, %s)"
            cursor.execute(sql, (ad_id,screen_id[0], start_time, end_time, selected_date, cost))
        except Exception as e:
            print(f"Error scheduling ad for screen {screen_name}: {e}")
            continue 

    conn.commit() 

    return jsonify({"message": "Ad schedule created successfully"}), 200
from datetime import datetime, time

@app.route("/calculate_cost", methods=["POST"])
def calculate_cost():
    data = request.get_json()

    # Extract necessary parameters from the request body
    start_time_str = data.get("start_time")
    end_time_str = data.get("end_time")
    location = data.get("location")
    business_type = data.get("business_type")
    screen_names_list = data.get("screen_names")

    # Extract screen names from the list of strings
    screen_names = [name.strip("{}'\"") for name in screen_names_list]

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Fetch screen IDs based on screen names, location, and business type
        cursor.execute("""
            SELECT screen_id FROM screens 
            WHERE screen_name = ANY(%s) AND location = %s AND business_type = %s
        """, (screen_names, location, business_type))
        screen_ids = cursor.fetchall()

        if screen_ids:
            # Iterate over each screen ID to calculate cost
            total_cost = 0
            for screen_id in screen_ids:
                # Fetch peak hour details for the screen
                cursor.execute("""
                    SELECT peak_hour_start, peak_hour_end, base_rate, peak_hr_multiplier 
                    FROM screens
                    WHERE screen_id = %s
                """, (screen_id,))
                peak_hour_details = cursor.fetchone()

                if peak_hour_details:
                    peak_hour_start_str, peak_hour_end_str, base_rate, peak_hr_multiplier = peak_hour_details
                    
                    # Extract only the time portion from start_time_str and end_time_str
                    start_time = datetime.strptime(start_time_str[-12:-4], '%H:%M:%S').time()
                    end_time = datetime.strptime(end_time_str[-12:-4], '%H:%M:%S').time()
                    print(peak_hour_start_str)
                    print(start_time)
                    # Calculate the total cost for this screen
                    if peak_hour_start_str <= start_time <= peak_hour_end_str or peak_hour_start_str <= end_time <= peak_hour_end_str:
                        cost = base_rate * peak_hr_multiplier
                    else:
                        cost = base_rate

                    total_cost += cost
                else:
                    return jsonify({"error": "Peak hour details not found for one of the screens"}), 404
            
            # Insert total cost into the ad_schedule table
            cursor.execute("""
                          UPDATE ad_schedule 
                          SET cost = %s 
                          WHERE start_time = %s AND end_time = %s
                      """, (total_cost, start_time, end_time))
            conn.commit()
            print(cost)
            print("success")
            return jsonify({"total_cost": total_cost}), 200
        else:
            return jsonify({"error": "No screens found for the given parameters"}), 404

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "An error occurred while calculating the cost"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/upload', methods=['POST'])
def upload_image():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        if not conn:
            return jsonify('Failed to connect to the database!', 500)

        image_file_name = request.form['image_file_name']
        advertiser_id = request.form['advertiser_id']

        # Prepare INSERT statement with RETURNING ad_id
        sql = "INSERT INTO ads (file_name, advertiser_id) VALUES (%s, %s) RETURNING ad_id;"

        try:
            cursor.execute(sql, (image_file_name, advertiser_id))
            # Fetch the ad_id value
            ad_id = cursor.fetchone()[0]
            conn.commit()
            print(ad_id)
            # Return the ad_id to the frontend
            return jsonify({'ad_id': ad_id}), 200
        
        except (Exception, psycopg2.Error) as error:
            print("Error while inserting file data:", error)
            conn.rollback()
            return jsonify(f'Failed to insert file data: {error}'), 400
        finally:
            if conn:
                cursor.close()
                conn.close()

    except Exception as e:
        print("Error uploading file:", e)
        return jsonify(f'Failed to upload file: {e}'), 400

#SUPER ADMIN
@app.route("/highest_spender", methods=["GET"])
def get_highest_spender():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        # SQL query to find user with highest total cost
        sql = """
                SELECT u.username, SUM(as_.cost) AS total_cost
                FROM users u
                INNER JOIN ads a ON u.id = a.advertiser_id
                INNER JOIN ad_schedule as_ ON a.ad_id = as_.ad_id
                GROUP BY u.username
                ORDER BY total_cost DESC
                LIMIT 1;
                """

        cursor.execute(sql)
        result = cursor.fetchone()

        if result:
            username = result[0]
            total_cost = float(result[1])  # Assuming cost is a numerical value
            return jsonify({"username": username, "total_cost": total_cost}), 200
        else:
            return jsonify({"message": "No ad schedules found"}), 404

    except Exception as e:
        print(f"Error retrieving highest spender: {e}")
        return jsonify({"error": "Failed to retrieve highest spender"}), 500
    
@app.route("/user_costs", methods=["GET"])
def get_user_costs():
    try:
        cursor = get_db_connection().cursor()

        # Join user and ad_schedule tables (assuming a foreign key relationship)
        cursor.execute("""
            SELECT u.username, COALESCE(SUM(as_.cost), 0) AS total_cost
            FROM users u
            LEFT JOIN screens s ON u.id = s.owner_id
            LEFT JOIN ads a ON s.owner_id = a.advertiser_id
            LEFT JOIN ad_schedule as_ ON a.ad_id = as_.ad_id
            GROUP BY u.username;


        """)

        user_costs = cursor.fetchall()

        # Format data for pie chart:
        data = []
        for username, total_cost in user_costs:
            data.append({"username": username, "cost": total_cost})
            print(username, total_cost)  # Print each username and total_cost pair
        print(data)  # Print the constructed data list
        return jsonify(data)
    except Exception as e:
        print(f"Error retrieving user costs: {e}")
        return jsonify({"error": "Failed to retrieve user costs"}), 500


@app.route("/usercount", methods=["GET"])
def get_user_count():
  try:
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT COUNT(*) FROM users")
    user_count = cursor.fetchone()[0]  # Extract the count from the query result

    return jsonify({"count": user_count})

  except Exception as e:
    print(f"Error retrieving user count: {e}")
    return jsonify({"error": "Failed to retrieve user count"}), 500
  
@app.route("/regcount1", methods=["GET"])
def get_screen_count1():
    try:
        # Replace with your actual database connection logic (e.g., using SQLAlchemy, etc.)
        connection = get_db_connection()
        cursor = connection.cursor()
        # Modify the query to count all screens
        cursor.execute("SELECT COUNT(*) FROM screens")
        result = cursor.fetchone()

        if result:
            screen_count = result[0]  # Extract the count from the query result
            return jsonify({"count": screen_count})
        else:
            return jsonify({"count": 0})  # Return 0 if no screens found

    except Exception as e:
        print(f"Error retrieving screen count: {e}")
        return jsonify({"error": "Failed to retrieve screen count"}), 500

@app.route("/grosscollection1", methods=["GET"])  # Ensure user_id is parsed as an integer
def get_grosscoll1():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        #print(user_id)
        # Use parameterized query to prevent SQL injection
        cursor.execute("SELECT SUM(cost) FROM ad_schedule")
        result = cursor.fetchone()

        if result:
            collection = float(result[0]) if result[0] else 0.0  # Extract the sum from the query result and cast to float
            return jsonify({"collection": collection})
        else:
            return jsonify({"collection": 0.0})  # Return 0 if no collection found for the user

    except Exception as e:
        print(f"Error retrieving gross collection for user{e}")
        return jsonify({"error": "Failed to retrieve gross collection"}), 500
if __name__ == '__main__':
  app.run(debug=True)
