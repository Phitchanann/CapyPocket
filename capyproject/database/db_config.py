import os
from pathlib import Path

import mysql.connector
from mysql.connector import Error as MySQLError


def _load_env_file(path):
    if not path.is_file():
        return

    for raw_line in path.read_text(encoding='utf-8').splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue

        key, value = line.split('=', 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


_load_env_file(Path(__file__).resolve().with_name('.env'))
_load_env_file(Path(__file__).resolve().parent.parent / '.env')


def _env(*names, default='', allow_empty=False):
    for name in names:
        value = os.getenv(name)
        if value is None:
            continue
        if allow_empty or value != '':
            return value
    return default


def _build_connection_kwargs(password_override=None):
    password = password_override
    if password is None:
        password = _env('CAPY_MYSQL_PASSWORD', 'DB_PASSWORD', default='', allow_empty=True)

    port_raw = _env('CAPY_MYSQL_PORT', 'DB_PORT', default='3306')
    try:
        port = int(port_raw)
    except ValueError:
        port = 3306

    return {
        'host': _env('CAPY_MYSQL_HOST', 'DB_HOST', default='localhost'),
        'port': port,
        'user': _env('CAPY_MYSQL_USER', 'DB_USER', default='root'),
        'password': password,
        'database': _env('CAPY_MYSQL_DATABASE', 'DB_NAME', default='capypocket'),
    }


def get_connection():
    kwargs = _build_connection_kwargs()
    try:
        return mysql.connector.connect(**kwargs)
    except MySQLError as first_error:
        # Some local dev MySQL setups keep root without a password.
        if first_error.errno == 1045 and kwargs.get('password'):
            try:
                return mysql.connector.connect(**_build_connection_kwargs(password_override=''))
            except MySQLError:
                pass
        raise