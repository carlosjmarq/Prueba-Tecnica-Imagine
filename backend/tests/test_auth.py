from fastapi.testclient import TestClient


def test_register_and_me(client: TestClient) -> None:
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "email": "carlos@example.com",
            "full_name": "Carlos",
            "password": "password123",
            "role": "CUSTOMER",
        },
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["email"] == "carlos@example.com"
    assert body["role"] == "CUSTOMER"
    assert "password" not in body

    login = client.post(
        "/api/v1/auth/login",
        json={"email": "carlos@example.com", "password": "password123"},
    )
    assert login.status_code == 200
    tokens = login.json()
    assert tokens["access_token"]
    assert tokens["refresh_token"]

    me = client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {tokens['access_token']}"}
    )
    assert me.status_code == 200
    assert me.json()["email"] == "carlos@example.com"


def test_duplicate_email_rejected(client: TestClient) -> None:
    payload = {
        "email": "dupe@example.com",
        "full_name": "Dupe",
        "password": "password123",
        "role": "CUSTOMER",
    }
    assert client.post("/api/v1/auth/register", json=payload).status_code == 201
    assert client.post("/api/v1/auth/register", json=payload).status_code == 409


def test_login_invalid_credentials(client: TestClient) -> None:
    resp = client.post(
        "/api/v1/auth/login", json={"email": "nobody@example.com", "password": "wrong"}
    )
    assert resp.status_code == 401


def test_refresh_token_rotation(client: TestClient) -> None:
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "rotate@example.com",
            "full_name": "Rota User",
            "password": "password123",
            "role": "CUSTOMER",
        },
    )
    login = client.post(
        "/api/v1/auth/login", json={"email": "rotate@example.com", "password": "password123"}
    )
    first_refresh = login.json()["refresh_token"]

    rotated = client.post("/api/v1/auth/refresh", json={"refresh_token": first_refresh})
    assert rotated.status_code == 200
    assert rotated.json()["access_token"]

    reused = client.post("/api/v1/auth/refresh", json={"refresh_token": first_refresh})
    assert reused.status_code == 401


def test_logout_revokes_refresh(client: TestClient) -> None:
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "logout@example.com",
            "full_name": "Logout User",
            "password": "password123",
            "role": "CUSTOMER",
        },
    )
    login = client.post(
        "/api/v1/auth/login", json={"email": "logout@example.com", "password": "password123"}
    )
    refresh = login.json()["refresh_token"]

    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": refresh}).status_code == 401


def test_protected_route_requires_token(client: TestClient) -> None:
    assert client.get("/api/v1/auth/me").status_code == 401
