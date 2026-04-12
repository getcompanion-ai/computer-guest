#!/usr/bin/env python3
import json
import socket
import sys
import time
from pathlib import Path


LISTEN_PORT = 1024
SSH_PORT = 2222
WAIT_TIMEOUT_SECONDS = 15.0
POLL_INTERVAL_SECONDS = 0.1
HOST_KEY_PATH = Path("/etc/ssh/ssh_host_ed25519_key.pub")


def log(message: str) -> None:
    print(f"[microagent-ready-agent] {message}", file=sys.stderr, flush=True)


def local_port_ready(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.settimeout(POLL_INTERVAL_SECONDS)
        try:
            probe.connect(("127.0.0.1", port))
        except OSError:
            return False
    return True


def wait_for_ready() -> str:
    deadline = time.monotonic() + WAIT_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        if HOST_KEY_PATH.is_file() and local_port_ready(SSH_PORT):
            return HOST_KEY_PATH.read_text(encoding="utf-8").strip()
        time.sleep(POLL_INTERVAL_SECONDS)
    raise TimeoutError("guest services did not become ready before timeout")


def handle_connection(connection: socket.socket) -> None:
    with connection:
        payload_line = b""
        while not payload_line.endswith(b"\n"):
            chunk = connection.recv(4096)
            if not chunk:
                break
            payload_line += chunk
        if not payload_line:
            return

        try:
            payload = json.loads(payload_line.decode("utf-8"))
            guest_ssh_public_key = wait_for_ready()
            response = {
                "status": "ok",
                "ready_nonce": str(payload.get("ready_nonce") or "").strip(),
                "guest_ssh_public_key": guest_ssh_public_key,
            }
        except Exception as exc:
            response = {"status": "error", "error": str(exc)}
        connection.sendall((json.dumps(response) + "\n").encode("utf-8"))


def main() -> int:
    cid_any = getattr(socket, "VMADDR_CID_ANY", 0xFFFFFFFF)
    with socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM) as listener:
        listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        listener.bind((cid_any, LISTEN_PORT))
        listener.listen()
        log(f"listening on vsock port {LISTEN_PORT}")
        while True:
            connection, _ = listener.accept()
            handle_connection(connection)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
