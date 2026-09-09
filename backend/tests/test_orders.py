from fastapi.testclient import TestClient

ORDER_PAYLOAD = {
    "pickup_address": "Cra 7 #12-34",
    "delivery_address": "Cll 45 #5-67",
    "notes": "Dejar en porteria",
    "items": [
        {"name": "Pizza", "price": 10.0, "quantity": 2},
        {"name": "Bebida", "price": 2.5, "quantity": 1},
    ],
}


def _create_order(client: TestClient, headers: dict[str, str]) -> dict:
    resp = client.post("/api/v1/orders", json=ORDER_PAYLOAD, headers=headers)
    assert resp.status_code == 201, resp.text
    return resp.json()


def test_customer_full_flow(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    assert order["status"] == "PENDING"
    assert order["total_amount"] == 22.5
    assert len(order["items"]) == 2
    assert len(order["history"]) == 1

    listing = client.get("/api/v1/orders", headers=auth_headers["customer"])
    assert listing.status_code == 200
    assert any(o["id"] == order["id"] for o in listing.json())

    detail = client.get(f"/api/v1/orders/{order['id']}", headers=auth_headers["customer"])
    assert detail.status_code == 200
    assert detail.json()["delivery_address"] == "Cll 45 #5-67"


def test_driver_accept_and_transition(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])

    available = client.get("/api/v1/orders/available", headers=auth_headers["driver"])
    assert available.status_code == 200
    assert any(o["id"] == order["id"] for o in available.json())

    accepted = client.post(f"/api/v1/orders/{order['id']}/accept", headers=auth_headers["driver"])
    assert accepted.status_code == 200
    assert accepted.json()["status"] == "ACCEPTED"
    assert accepted.json()["driver_id"] is not None

    picked = client.post(
        f"/api/v1/orders/{order['id']}/status",
        json={"status": "PICKED_UP"},
        headers=auth_headers["driver"],
    )
    assert picked.status_code == 200
    assert picked.json()["status"] == "PICKED_UP"

    delivered = client.post(
        f"/api/v1/orders/{order['id']}/status",
        json={"status": "DELIVERED"},
        headers=auth_headers["driver"],
    )
    assert delivered.status_code == 200
    assert delivered.json()["status"] == "DELIVERED"

    mine = client.get("/api/v1/orders/mine", headers=auth_headers["driver"])
    assert any(o["id"] == order["id"] for o in mine.json())


def test_double_accept_rejected(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    assert (
        client.post(
            f"/api/v1/orders/{order['id']}/accept", headers=auth_headers["driver"]
        ).status_code
        == 200
    )

    # segundo driver no puede aceptar un pedido ya asignado
    headers2 = auth_headers["driver"].copy()
    assert client.post(f"/api/v1/orders/{order['id']}/accept", headers=headers2).status_code == 409


def test_invalid_transition_rejected(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    client.post(f"/api/v1/orders/{order['id']}/accept", headers=auth_headers["driver"])
    # ACCEPTED -> DELIVERED no es valida (falta PICKED_UP)
    resp = client.post(
        f"/api/v1/orders/{order['id']}/status",
        json={"status": "DELIVERED"},
        headers=auth_headers["driver"],
    )
    assert resp.status_code == 409


def test_only_assigned_driver_updates(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    # driver no asignado intenta actualizar estado
    resp = client.post(
        f"/api/v1/orders/{order['id']}/status",
        json={"status": "PICKED_UP"},
        headers=auth_headers["driver"],
    )
    assert resp.status_code == 403


def test_customer_cancels_pending(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    cancelled = client.post(
        f"/api/v1/orders/{order['id']}/cancel", headers=auth_headers["customer"]
    )
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "CANCELLED"


def test_customer_cannot_cancel_accepted(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    client.post(f"/api/v1/orders/{order['id']}/accept", headers=auth_headers["driver"])
    resp = client.post(f"/api/v1/orders/{order['id']}/cancel", headers=auth_headers["customer"])
    assert resp.status_code == 409


def test_customer_cannot_see_others_orders(client: TestClient, auth_headers: dict) -> None:
    order = _create_order(client, auth_headers["customer"])
    # registrar un segundo customer
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "other@example.com",
            "full_name": "Other User",
            "password": "password123",
            "role": "CUSTOMER",
        },
    )
    login = client.post(
        "/api/v1/auth/login", json={"email": "other@example.com", "password": "password123"}
    )
    assert login.status_code == 200, login.text
    other_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert client.get(f"/api/v1/orders/{order['id']}", headers=other_headers).status_code == 403
