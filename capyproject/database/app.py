import os

from flask import Flask, request, jsonify
from mysql.connector import Error as MySQLError
from db_config import get_connection

app = Flask(__name__)
DEFAULT_USER_ID = 1


@app.route('/')
def route_index():
    return jsonify({'ok': True, 'message': 'CapyPocket API is running'}), 200


def verify_database_connection():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


def get_json_or_400(required_fields=None):
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'error': 'Request body must be valid JSON'}), 400)

    if required_fields:
        missing = [field for field in required_fields if field not in data]
        if missing:
            return None, (jsonify({'error': f"Missing required fields: {', '.join(missing)}"}), 400)

    return data, None


# ---------------------------------------------------------------------------
# TRANSACTIONS
# ---------------------------------------------------------------------------

# Get all transactions (READ in CRUD)
def get_all_transactions():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, title, category, note, amount, type, created_at
            FROM transactions
            WHERE user_id = %s AND deleted_at IS NULL
            ORDER BY created_at DESC
        """, (DEFAULT_USER_ID,))
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()


# Create a transaction (CREATE in CRUD)
def create_transaction(title, category, note, amount, type_, created_at):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (DEFAULT_USER_ID, title, category, note, amount, type_, created_at))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# Update a transaction (UPDATE in CRUD)
def update_transaction(transaction_id, title, category, note, amount, type_, created_at):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            UPDATE transactions
            SET title = %s,
                category = %s,
                note = %s,
                amount = %s,
                type = %s,
                created_at = %s
                        WHERE id = %s
                            AND user_id = %s
                            AND deleted_at IS NULL
        """, (title, category, note, amount, type_, created_at, transaction_id, DEFAULT_USER_ID))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# Delete a transaction (DELETE in CRUD)
def delete_transaction(transaction_id):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            UPDATE transactions
            SET deleted_at = NOW(3)
            WHERE id = %s AND user_id = %s AND deleted_at IS NULL
        """, (transaction_id, DEFAULT_USER_ID))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# Get one transaction by ID (R in CRUD)
def get_transaction_by_id(transaction_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, title, category, note, amount, type, created_at
            FROM transactions
            WHERE id = %s AND user_id = %s AND deleted_at IS NULL
        """, (transaction_id, DEFAULT_USER_ID))
        return cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


# Get all transactions with category count grouped by category (JOIN + GROUP BY)
def get_transaction_summary_by_category():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT
                c.id AS category_id,
                c.name AS category_name,
                COUNT(t.id) AS transaction_count,
                COALESCE(SUM(t.amount), 0) AS total_amount
            FROM categories c
            LEFT JOIN transactions t
                ON t.category = c.name
                AND t.user_id = c.user_id
                AND t.deleted_at IS NULL
            WHERE c.user_id = %s AND c.deleted_at IS NULL
            GROUP BY c.id, c.name
            ORDER BY c.name
        """, (DEFAULT_USER_ID,))
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# CATEGORIES
# ---------------------------------------------------------------------------

# Get all categories (READ in CRUD)
def get_all_categories():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, name, icon_code, color_value
            FROM categories
            WHERE user_id = %s AND deleted_at IS NULL
            ORDER BY name
        """, (DEFAULT_USER_ID,))
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()


# Create a category (CREATE in CRUD)
def create_category(name, icon_code, color_value):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO categories (user_id, name, icon_code, color_value)
            VALUES (%s, %s, %s, %s)
        """, (DEFAULT_USER_ID, name, icon_code, color_value))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# GOALS
# ---------------------------------------------------------------------------

# Get all goals (READ in CRUD)
def get_all_goals():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, name, target_amount, saved_amount, created_at
            FROM goals
            WHERE user_id = %s AND deleted_at IS NULL
            ORDER BY created_at DESC
        """, (DEFAULT_USER_ID,))
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()


# Create a goal (CREATE in CRUD)
def create_goal(name, target_amount, saved_amount, created_at):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at)
            VALUES (%s, %s, %s, %s, %s)
        """, (DEFAULT_USER_ID, name, target_amount, saved_amount, created_at))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# Update a goal (UPDATE in CRUD)
def update_goal(goal_id, name, target_amount, saved_amount, created_at):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            UPDATE goals
            SET name = %s,
                target_amount = %s,
                saved_amount = %s,
                created_at = %s
                        WHERE id = %s
                            AND user_id = %s
                            AND deleted_at IS NULL
        """, (name, target_amount, saved_amount, created_at, goal_id, DEFAULT_USER_ID))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# Delete a goal (DELETE in CRUD)
def delete_goal(goal_id):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            UPDATE goals
            SET deleted_at = NOW(3)
            WHERE id = %s AND user_id = %s AND deleted_at IS NULL
        """, (goal_id, DEFAULT_USER_ID))
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# Get one goal by ID (R in CRUD)
def get_goal_by_id(goal_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, name, target_amount, saved_amount, created_at
            FROM goals
            WHERE id = %s AND user_id = %s AND deleted_at IS NULL
        """, (goal_id, DEFAULT_USER_ID))
        return cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# FLASK ROUTES — TRANSACTIONS
# ---------------------------------------------------------------------------

@app.route('/transactions', methods=['GET'])
def route_get_all_transactions():
    rows = get_all_transactions()
    for row in rows:
        if row.get('created_at'):
            row['created_at'] = str(row['created_at'])
        if row.get('amount') is not None:
            row['amount'] = float(row['amount'])
    return jsonify(rows), 200


@app.route('/transactions', methods=['POST'])
def route_create_transaction():
    data, error = get_json_or_400(['title', 'category', 'amount', 'type', 'created_at'])
    if error:
        return error
    try:
        create_transaction(
            data['title'],
            data['category'],
            data.get('note', ''),
            data['amount'],
            data['type'],
            data['created_at'],
        )
        return jsonify({'message': 'Transaction created'}), 201
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


@app.route('/transactions/<int:transaction_id>', methods=['GET'])
def route_get_transaction_by_id(transaction_id):
    row = get_transaction_by_id(transaction_id)
    if row is None:
        return jsonify({'error': 'Transaction not found'}), 404
    if row.get('created_at'):
        row['created_at'] = str(row['created_at'])
    if row.get('amount') is not None:
        row['amount'] = float(row['amount'])
    return jsonify(row), 200


@app.route('/transactions/<int:transaction_id>', methods=['PUT'])
def route_update_transaction(transaction_id):
    data, error = get_json_or_400(['title', 'category', 'amount', 'type', 'created_at'])
    if error:
        return error
    try:
        update_transaction(
            transaction_id,
            data['title'],
            data['category'],
            data.get('note', ''),
            data['amount'],
            data['type'],
            data['created_at'],
        )
        return jsonify({'message': 'Transaction updated'}), 200
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


@app.route('/transactions/<int:transaction_id>', methods=['DELETE'])
def route_delete_transaction(transaction_id):
    delete_transaction(transaction_id)
    return jsonify({'message': f'Transaction {transaction_id} deleted'}), 200


@app.route('/transactions/summary/by-category', methods=['GET'])
def route_transaction_summary_by_category():
    rows = get_transaction_summary_by_category()
    for row in rows:
        if row.get('total_amount') is not None:
            row['total_amount'] = float(row['total_amount'])
    return jsonify(rows), 200


@app.route('/health/database', methods=['GET'])
def route_database_health():
    try:
        verify_database_connection()
        return jsonify({'ok': True, 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'ok': False, 'database': 'disconnected', 'error': str(e)}), 500


# ---------------------------------------------------------------------------
# FLASK ROUTES — CATEGORIES
# ---------------------------------------------------------------------------

@app.route('/categories', methods=['GET'])
def route_get_all_categories():
    rows = get_all_categories()
    return jsonify(rows), 200


@app.route('/categories', methods=['POST'])
def route_create_category():
    data, error = get_json_or_400(['name', 'icon_code', 'color_value'])
    if error:
        return error
    try:
        create_category(
            data['name'],
            data['icon_code'],
            data['color_value'],
        )
        return jsonify({'message': 'Category created'}), 201
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


# ---------------------------------------------------------------------------
# FLASK ROUTES — GOALS
# ---------------------------------------------------------------------------

@app.route('/goals', methods=['GET'])
def route_get_all_goals():
    rows = get_all_goals()
    for row in rows:
        if row.get('created_at'):
            row['created_at'] = str(row['created_at'])
        if row.get('target_amount') is not None:
            row['target_amount'] = float(row['target_amount'])
        if row.get('saved_amount') is not None:
            row['saved_amount'] = float(row['saved_amount'])
    return jsonify(rows), 200


@app.route('/goals', methods=['POST'])
def route_create_goal():
    data, error = get_json_or_400(['name', 'target_amount', 'created_at'])
    if error:
        return error
    try:
        create_goal(
            data['name'],
            data['target_amount'],
            data.get('saved_amount', 0),
            data['created_at'],
        )
        return jsonify({'message': 'Goal created'}), 201
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


@app.route('/goals/<int:goal_id>', methods=['GET'])
def route_get_goal_by_id(goal_id):
    row = get_goal_by_id(goal_id)
    if row is None:
        return jsonify({'error': 'Goal not found'}), 404
    if row.get('created_at'):
        row['created_at'] = str(row['created_at'])
    if row.get('target_amount') is not None:
        row['target_amount'] = float(row['target_amount'])
    if row.get('saved_amount') is not None:
        row['saved_amount'] = float(row['saved_amount'])
    return jsonify(row), 200


@app.route('/goals/<int:goal_id>', methods=['PUT'])
def route_update_goal(goal_id):
    data, error = get_json_or_400(['name', 'target_amount', 'created_at'])
    if error:
        return error
    try:
        update_goal(
            goal_id,
            data['name'],
            data['target_amount'],
            data.get('saved_amount', 0),
            data['created_at'],
        )
        return jsonify({'message': 'Goal updated'}), 200
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


@app.route('/goals/<int:goal_id>', methods=['DELETE'])
def route_delete_goal(goal_id):
    delete_goal(goal_id)
    return jsonify({'message': f'Goal {goal_id} deleted'}), 200


# ---------------------------------------------------------------------------

if __name__ == '__main__':
    skip_db_check = os.getenv('SKIP_DB_CHECK', '').strip().lower() in {'1', 'true', 'yes', 'on'}

    if skip_db_check:
        print('MySQL startup check: SKIPPED (SKIP_DB_CHECK=1)')
    else:
        try:
            verify_database_connection()
            print('MySQL connection: OK')
        except Exception as e:
            print(f'MySQL connection: FAILED - {e}')
            print('Check DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, and whether MySQL is running.')
            raise SystemExit(1)

    # Keep debugger on, but disable auto-reloader to avoid repeated Windows watchdog restarts.
    app.run(debug=True, use_reloader=False, host='0.0.0.0', port=5000)
