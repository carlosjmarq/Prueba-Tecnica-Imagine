import json
import logging
import os
import ssl
import urllib.parse
from datetime import datetime, timedelta, timezone
from typing import Any

import boto3
import pg8000.native

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_ssm = boto3.client("ssm")


def _get_parameter(name: str) -> str:
    response = _ssm.get_parameter(Name=name, WithDecryption=True)
    return str(response["Parameter"]["Value"])


def _parse_asyncpg_url(database_url: str) -> dict[str, Any]:
    scheme, rest = database_url.split("://", 1)
    if not scheme.startswith("postgresql"):
        raise ValueError("DATABASE_URL no es una URL de PostgreSQL")

    userinfo, hostinfo = rest.rsplit("@", 1)
    user, _, password = userinfo.partition(":")
    hostport, _, database = hostinfo.partition("/")
    host, _, port = hostport.partition(":")

    return {
        "user": urllib.parse.unquote(user),
        "password": urllib.parse.unquote(password),
        "host": host,
        "port": int(port or "5432"),
        "database": database.split("?", 1)[0],
    }


def _connect(params: dict[str, Any]) -> "pg8000.native.Connection":
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    return pg8000.native.Connection(
        user=params["user"],
        password=params["password"],
        host=params["host"],
        port=params["port"],
        database=params["database"],
        ssl_context=context,
    )


def handler(event: dict[str, Any], context: Any) -> dict[str, int]:
    timeout_minutes = int(os.environ.get("ORDER_TIMEOUT_MINUTES", "15"))
    database_url = _get_parameter(os.environ["SSM_DB_URL_PARAM"])
    db_password = _get_parameter(os.environ["SSM_DB_PASSWORD_PARAM"])

    params = _parse_asyncpg_url(database_url)
    if db_password:
        params["password"] = db_password

    cutoff = datetime.now(timezone.utc) - timedelta(minutes=timeout_minutes)
    connection = _connect(params)
    cancelled = 0

    try:
        pending = connection.run(
            "SELECT id FROM orders WHERE status = 'PENDING' AND created_at < :cutoff",
            cutoff=cutoff,
        )

        for row in pending:
            order_id = row[0]
            updated = connection.run(
                "UPDATE orders SET status = 'CANCELLED', updated_at = now() "
                "WHERE id = :order_id AND status = 'PENDING' RETURNING id",
                order_id=order_id,
            )
            if not updated:
                continue

            connection.run(
                "INSERT INTO order_status_history "
                "(order_id, from_status, to_status, changed_at) "
                "VALUES (:order_id, 'PENDING', 'CANCELLED', now())",
                order_id=order_id,
            )
            cancelled += 1

    finally:
        connection.close()

    logger.info(json.dumps({"cancelled": cancelled, "timeout_minutes": timeout_minutes}))
    return {"cancelled": cancelled}
