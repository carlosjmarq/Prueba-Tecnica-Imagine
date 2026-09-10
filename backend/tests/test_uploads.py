import io

import httpx
from fastapi.testclient import TestClient

PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64


def test_upload_image_ok(client: TestClient, auth_headers: dict) -> None:
    files = {"file": ("foto.png", io.BytesIO(PNG), "image/png")}
    resp = client.post("/api/v1/uploads/images", files=files, headers=auth_headers["customer"])
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["key"].startswith("users/")
    assert "localhost:9000" in body["url"] or "delivery-media" in body["url"]


def test_upload_rejects_unsupported_type(client: TestClient, auth_headers: dict) -> None:
    files = {"file": ("doc.txt", io.BytesIO(b"hola"), "text/plain")}
    resp = client.post("/api/v1/uploads/images", files=files, headers=auth_headers["customer"])
    assert resp.status_code == 415


def test_upload_requires_auth(client: TestClient) -> None:
    files = {"file": ("foto.png", io.BytesIO(PNG), "image/png")}
    resp = client.post("/api/v1/uploads/images", files=files)
    assert resp.status_code == 401


def test_get_image_proxy(client: TestClient, auth_headers: dict) -> None:
    files = {"file": ("foto.png", io.BytesIO(PNG), "image/png")}
    uploaded = client.post("/api/v1/uploads/images", files=files, headers=auth_headers["customer"])
    key = uploaded.json()["key"]

    resp = client.get(f"/api/v1/uploads/images/{key}", headers=auth_headers["customer"])
    assert resp.status_code == 200, resp.text
    assert resp.content == PNG
    assert resp.headers["content-type"] == "image/png"


def test_get_image_requires_auth(client: TestClient, auth_headers: dict) -> None:
    files = {"file": ("foto.png", io.BytesIO(PNG), "image/png")}
    uploaded = client.post("/api/v1/uploads/images", files=files, headers=auth_headers["customer"])
    key = uploaded.json()["key"]
    assert client.get(f"/api/v1/uploads/images/{key}").status_code == 401


def test_get_image_not_found(client: TestClient, auth_headers: dict) -> None:
    resp = client.get(
        "/api/v1/uploads/images/users/nadie/images/fantasma.png",
        headers=auth_headers["customer"],
    )
    assert resp.status_code == 404


def test_presign_requires_auth(client: TestClient) -> None:
    resp = client.post("/api/v1/uploads/presign", json={"content_type": "image/png"})
    assert resp.status_code == 401


def test_presign_rejects_unsupported_type(client: TestClient, auth_headers: dict) -> None:
    resp = client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "text/plain"},
        headers=auth_headers["customer"],
    )
    assert resp.status_code == 415


def test_presign_returns_put_url(client: TestClient, auth_headers: dict) -> None:
    resp = client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/png"},
        headers=auth_headers["customer"],
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["key"].startswith("users/")
    assert body["key"] in body["url"]
    # MinIO puede firmar con V2 (Signature=) o V4 (X-Amz-Signature).
    assert "Signature" in body["url"]


def test_presign_round_trip(client: TestClient, auth_headers: dict) -> None:
    """Presign -> PUT directo a MinIO -> lectura por el proxy devuelve los bytes."""
    presigned = client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/png"},
        headers=auth_headers["customer"],
    ).json()
    with httpx.Client(timeout=15) as http:
        put = http.put(
            presigned["url"],
            content=PNG,
            headers={"Content-Type": "image/png"},
        )
    assert put.status_code == 200, put.text

    resp = client.get(
        f"/api/v1/uploads/images/{presigned['key']}",
        headers=auth_headers["customer"],
    )
    assert resp.status_code == 200, resp.text
    assert resp.content == PNG
