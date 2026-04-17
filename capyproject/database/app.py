import hashlib
import os
import uuid
from datetime import datetime, timedelta, timezone
from functools import wraps
from pathlib import Path

import bcrypt
import jwt
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from mysql.connector import Error as MySQLError
from werkzeug.utils import secure_filename

from db_config import get_connection

app = Flask(__name__)
CORS(app)

JWT_SECRET = os.getenv('JWT_SECRET', 'change_me_to_a_long_random_secret_at_least_32_chars')
JWT_EXPIRES_HOURS = int(os.getenv('JWT_EXPIRES_HOURS', '168'))  # 7 days

UPLOADS_DIR = Path(__file__).parent / 'uploads' / 'receipts'
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
MAX_UPLOAD_BYTES = 5 * 1024 * 1024
ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.heic'}


# ---------------------------------------------------------------------------
# AUTH HELPERS
# ---------------------------------------------------------------------------

def _sign_token(user_id: int) -> str:
    payload = {
        'userId': user_id,
        'exp': datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRES_HOURS),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm='HS256')


def _check_password(plain: str, stored_hash: str) -> bool:
    """Accept both bcrypt ($2b$...) and legacy SHA-256 hashes."""
    if stored_hash.startswith('$2'):
        return bcrypt.checkpw(plain.encode(), stored_hash.encode())
    return hashlib.sha256(plain.encode()).hexdigest() == stored_hash


def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        header = request.headers.get('Authorization', '')
        if not header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid Authorization header'}), 401
        token = header[7:]
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            request.user_id = payload['userId']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        return f(*args, **kwargs)
    return decorated


def get_json_or_400(required_fields=None):
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'error': 'Request body must be valid JSON'}), 400)
    if required_fields:
        missing = [f for f in required_fields if f not in data]
        if missing:
            return None, (jsonify({'error': f"Missing required fields: {', '.join(missing)}"}), 400)
    return data, None


# ---------------------------------------------------------------------------
# INDEX / HEALTH
# ---------------------------------------------------------------------------

@app.route('/')
def route_index():
    return jsonify({'ok': True, 'message': 'CapyPocket API is running'}), 200


@app.route('/health/database', methods=['GET'])
def route_database_health():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify({'ok': True, 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'ok': False, 'database': 'disconnected', 'error': str(e)}), 500


# ---------------------------------------------------------------------------
# AUTH ROUTES
# ---------------------------------------------------------------------------

@app.route('/auth/register', methods=['POST'])
def route_register():
    data, error = get_json_or_400(['username', 'password'])
    if error:
        return error

    username = data['username'].strip()
    password = data['password']
    email = (data.get('email') or '').strip() or None
    display_name = (data.get('display_name') or '').strip() or username

    if len(username) < 2:
        return jsonify({'error': 'Username must be at least 2 characters'}), 400
    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400

    password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'INSERT INTO users (username, email, password_hash, display_name) VALUES (%s, %s, %s, %s)',
            (username, email, password_hash, display_name),
        )
        conn.commit()
        user_id = cursor.lastrowid
        token = _sign_token(user_id)
        return jsonify({
            'message': 'Registration successful',
            'token': token,
            'user': {'id': user_id, 'username': username, 'email': email, 'display_name': display_name},
        }), 201
    except MySQLError as e:
        if e.errno == 1062:
            return jsonify({'error': 'Username or email already taken'}), 409
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()


@app.route('/auth/login', methods=['POST'])
def route_login():
    data, error = get_json_or_400(['password'])
    if error:
        return error

    identifier = (data.get('username') or data.get('email') or '').strip()
    if not identifier:
        return jsonify({'error': 'Provide username or email'}), 400

    password = data['password']

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, username, email, password_hash, display_name '
            'FROM users WHERE (username = %s OR email = %s) AND password_hash IS NOT NULL LIMIT 1',
            (identifier, identifier),
        )
        row = cursor.fetchone()

        if row is None:
            # Constant-time non-match to prevent user enumeration
            hashlib.sha256(password.encode()).hexdigest()
            return jsonify({'error': 'Invalid credentials'}), 401

        if not _check_password(password, row['password_hash']):
            return jsonify({'error': 'Invalid credentials'}), 401

        token = _sign_token(row['id'])
        return jsonify({
            'token': token,
            'user': {
                'id': row['id'],
                'username': row['username'],
                'email': row['email'],
                'display_name': row['display_name'],
            },
        })
    finally:
        cursor.close()
        conn.close()


@app.route('/auth/me', methods=['GET'])
@require_auth
def route_me():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, username, email, display_name, monthly_income, cash_balance, pocket_saved, savings_goal '
            'FROM users WHERE id = %s',
            (request.user_id,),
        )
        row = cursor.fetchone()
        if row is None:
            return jsonify({'error': 'User not found'}), 404
        for field in ('monthly_income', 'cash_balance', 'pocket_saved', 'savings_goal'):
            if row.get(field) is not None:
                row[field] = float(row[field])
        return jsonify(row)
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# IMAGE UPLOAD
# ---------------------------------------------------------------------------

@app.route('/upload/receipt', methods=['POST'])
@require_auth
def route_upload_receipt():
    if 'receipt' not in request.files:
        return jsonify({'error': 'No file received — send as multipart/form-data, field name "receipt"'}), 400

    file = request.files['receipt']
    if not file.filename:
        return jsonify({'error': 'Empty filename'}), 400

    ext = Path(file.filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        return jsonify({'error': f'Unsupported file type "{ext}". Allowed: jpg, png, webp, heic'}), 400

    filename = f'receipt_{request.user_id}_{uuid.uuid4().hex}{ext}'
    save_path = UPLOADS_DIR / filename

    file.save(str(save_path))

    # Reject oversized files after save (stream may not have content-length)
    if save_path.stat().st_size > MAX_UPLOAD_BYTES:
        save_path.unlink(missing_ok=True)
        return jsonify({'error': f'File too large (max 5 MB)'}), 413

    base_url = os.getenv('BASE_URL', f'http://localhost:{os.getenv("PORT", "5000")}')
    image_url = f'{base_url}/uploads/receipts/{filename}'
    return jsonify({'message': 'Receipt uploaded successfully', 'receipt_image_url': image_url}), 201


@app.route('/uploads/receipts/<path:filename>')
def route_serve_receipt(filename):
    return send_from_directory(str(UPLOADS_DIR), secure_filename(filename))


# ---------------------------------------------------------------------------
# TRANSACTION HELPERS
# ---------------------------------------------------------------------------

def _format_tx_row(row: dict) -> dict:
    if row.get('created_at'):
        row['created_at'] = str(row['created_at'])
    if row.get('amount') is not None:
        row['amount'] = float(row['amount'])
    row.setdefault('receipt_image_url', None)
    return row


def _get_all_transactions(user_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, title, category, note, amount, type, receipt_image_url, created_at '
            'FROM transactions WHERE user_id = %s AND deleted_at IS NULL ORDER BY created_at DESC',
            (user_id,),
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()


def _get_transaction_by_id(tx_id: int, user_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, title, category, note, amount, type, receipt_image_url, created_at '
            'FROM transactions WHERE id = %s AND user_id = %s AND deleted_at IS NULL',
            (tx_id, user_id),
        )
        return cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


def _create_transaction(user_id, title, category, note, amount, type_, created_at, receipt_image_url=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO transactions (user_id, title, category, note, amount, type, created_at, receipt_image_url) '
            'VALUES (%s, %s, %s, %s, %s, %s, %s, %s)',
            (user_id, title, category, note, amount, type_, created_at, receipt_image_url),
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        cursor.close()
        conn.close()


def _update_transaction(tx_id, user_id, title, category, note, amount, type_, created_at, receipt_image_url=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'UPDATE transactions SET title=%s, category=%s, note=%s, amount=%s, type=%s, '
            'created_at=%s, receipt_image_url=%s WHERE id=%s AND user_id=%s AND deleted_at IS NULL',
            (title, category, note, amount, type_, created_at, receipt_image_url, tx_id, user_id),
        )
        conn.commit()
        return cursor.rowcount
    finally:
        cursor.close()
        conn.close()


def _delete_transaction(tx_id: int, user_id: int):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'UPDATE transactions SET deleted_at = NOW(3) WHERE id = %s AND user_id = %s AND deleted_at IS NULL',
            (tx_id, user_id),
        )
        conn.commit()
        return cursor.rowcount
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# TRANSACTION ROUTES
# ---------------------------------------------------------------------------

@app.route('/transactions', methods=['GET'])
@require_auth
def route_get_all_transactions():
    rows = _get_all_transactions(request.user_id)
    return jsonify([_format_tx_row(r) for r in rows]), 200


@app.route('/transactions', methods=['POST'])
@require_auth
def route_create_transaction():
    data, error = get_json_or_400(['title', 'category', 'amount', 'type', 'created_at'])
    if error:
        return error
    try:
        tx_id = _create_transaction(
            request.user_id,
            data['title'],
            data['category'],
            data.get('note', ''),
            data['amount'],
            data['type'],
            data['created_at'],
            data.get('receipt_image_url'),
        )
        return jsonify({'message': 'Transaction created', 'id': tx_id}), 201
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


@app.route('/transactions/<int:transaction_id>', methods=['GET'])
@require_auth
def route_get_transaction_by_id(transaction_id):
    row = _get_transaction_by_id(transaction_id, request.user_id)
    if row is None:
        return jsonify({'error': 'Transaction not found'}), 404
    return jsonify(_format_tx_row(row)), 200


@app.route('/transactions/<int:transaction_id>', methods=['PUT'])
@require_auth
def route_update_transaction(transaction_id):
    data, error = get_json_or_400(['title', 'category', 'amount', 'type', 'created_at'])
    if error:
        return error
    try:
        affected = _update_transaction(
            transaction_id,
            request.user_id,
            data['title'],
            data['category'],
            data.get('note', ''),
            data['amount'],
            data['type'],
            data['created_at'],
            data.get('receipt_image_url'),
        )
        if affected == 0:
            return jsonify({'error': 'Transaction not found'}), 404
        return jsonify({'message': 'Transaction updated'}), 200
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400


@app.route('/transactions/<int:transaction_id>', methods=['DELETE'])
@require_auth
def route_delete_transaction(transaction_id):
    affected = _delete_transaction(transaction_id, request.user_id)
    if affected == 0:
        return jsonify({'error': 'Transaction not found'}), 404
    return jsonify({'message': f'Transaction {transaction_id} deleted'}), 200


@app.route('/transactions/summary/by-category', methods=['GET'])
@require_auth
def route_transaction_summary_by_category():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT c.id AS category_id, c.name AS category_name, '
            'COUNT(t.id) AS transaction_count, COALESCE(SUM(t.amount), 0) AS total_amount '
            'FROM categories c '
            'LEFT JOIN transactions t ON t.category = c.name AND t.user_id = c.user_id AND t.deleted_at IS NULL '
            'WHERE c.user_id = %s AND c.deleted_at IS NULL '
            'GROUP BY c.id, c.name ORDER BY c.name',
            (request.user_id,),
        )
        rows = cursor.fetchall()
        for row in rows:
            if row.get('total_amount') is not None:
                row['total_amount'] = float(row['total_amount'])
        return jsonify(rows), 200
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# CATEGORY ROUTES
# ---------------------------------------------------------------------------

@app.route('/categories', methods=['GET'])
@require_auth
def route_get_all_categories():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, name, icon_code, color_value FROM categories '
            'WHERE user_id = %s AND deleted_at IS NULL ORDER BY name',
            (request.user_id,),
        )
        return jsonify(cursor.fetchall()), 200
    finally:
        cursor.close()
        conn.close()


@app.route('/categories', methods=['POST'])
@require_auth
def route_create_category():
    data, error = get_json_or_400(['name', 'icon_code', 'color_value'])
    if error:
        return error
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO categories (user_id, name, icon_code, color_value) VALUES (%s, %s, %s, %s)',
            (request.user_id, data['name'], data['icon_code'], data['color_value']),
        )
        conn.commit()
        return jsonify({'message': 'Category created', 'id': cursor.lastrowid}), 201
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------
# GOAL HELPERS
# ---------------------------------------------------------------------------

def _format_goal_row(row: dict) -> dict:
    if row.get('created_at'):
        row['created_at'] = str(row['created_at'])
    for field in ('target_amount', 'saved_amount'):
        if row.get(field) is not None:
            row[field] = float(row[field])
    return row


# ---------------------------------------------------------------------------
# GOAL ROUTES
# ---------------------------------------------------------------------------

@app.route('/goals', methods=['GET'])
@require_auth
def route_get_all_goals():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, name, target_amount, saved_amount, created_at FROM goals '
            'WHERE user_id = %s AND deleted_at IS NULL ORDER BY created_at DESC',
            (request.user_id,),
        )
        return jsonify([_format_goal_row(r) for r in cursor.fetchall()]), 200
    finally:
        cursor.close()
        conn.close()


@app.route('/goals', methods=['POST'])
@require_auth
def route_create_goal():
    data, error = get_json_or_400(['name', 'target_amount', 'created_at'])
    if error:
        return error
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at) VALUES (%s, %s, %s, %s, %s)',
            (request.user_id, data['name'], data['target_amount'], data.get('saved_amount', 0), data['created_at']),
        )
        conn.commit()
        return jsonify({'message': 'Goal created', 'id': cursor.lastrowid}), 201
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()


@app.route('/goals/<int:goal_id>', methods=['GET'])
@require_auth
def route_get_goal_by_id(goal_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, name, target_amount, saved_amount, created_at FROM goals '
            'WHERE id = %s AND user_id = %s AND deleted_at IS NULL',
            (goal_id, request.user_id),
        )
        row = cursor.fetchone()
        if row is None:
            return jsonify({'error': 'Goal not found'}), 404
        return jsonify(_format_goal_row(row)), 200
    finally:
        cursor.close()
        conn.close()


@app.route('/goals/<int:goal_id>', methods=['PUT'])
@require_auth
def route_update_goal(goal_id):
    data, error = get_json_or_400(['name', 'target_amount', 'created_at'])
    if error:
        return error
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'UPDATE goals SET name=%s, target_amount=%s, saved_amount=%s, created_at=%s '
            'WHERE id=%s AND user_id=%s AND deleted_at IS NULL',
            (data['name'], data['target_amount'], data.get('saved_amount', 0), data['created_at'], goal_id, request.user_id),
        )
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify({'error': 'Goal not found'}), 404
        return jsonify({'message': 'Goal updated'}), 200
    except MySQLError as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()


@app.route('/goals/<int:goal_id>', methods=['DELETE'])
@require_auth
def route_delete_goal(goal_id):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'UPDATE goals SET deleted_at = NOW(3) WHERE id = %s AND user_id = %s AND deleted_at IS NULL',
            (goal_id, request.user_id),
        )
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify({'error': 'Goal not found'}), 404
        return jsonify({'message': f'Goal {goal_id} deleted'}), 200
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------------------------------------------

def verify_database_connection():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


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

    app.run(debug=True, use_reloader=False, host='0.0.0.0', port=int(os.getenv('PORT', '5000')))
