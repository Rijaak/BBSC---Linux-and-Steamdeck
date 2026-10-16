#!/usr/bin/env python3
"""BBSC account + server setup for the Linux emulator build (replaces the launcher's Accounts tab).

Usage:
  bbsc-setup.py --card /path/to/BBSC-card-*.json --name MyHunter --password secret
  bbsc-setup.py --server host:31313 --key REGKEY --name MyHunter --password secret
  bbsc-setup.py --card ... --name ... --password ... --no-register   # account already exists

What it does:
  1. creates the account on the shadNet server (same wire protocol as the launcher), unless --no-register
  2. writes the account into <user>/users.json (first user, or --user-id N)
  3. sets shadnet_server / webapi, shad_net_enabled and connected_to_network in <user>/config.json
  4. writes <user>/host_overrides.json so the game's server list and summons go to the community server
  5. copies the card into <user>/servers/

<user> is ~/.local/share/shadPS4, or ./user next to this script if that folder exists (portable).
"""
import argparse, json, os, socket, sys, shutil, pathlib

def varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F; n >>= 7
        if n: out.append(b | 0x80)
        else: out.append(b); return bytes(out)

def put_string(buf, field, text):
    if not text: return
    data = text.encode("utf-8")
    buf += varint((field << 3) | 2) + varint(len(data)) + data

def read_exact(sock, n):
    out = b""
    while len(out) < n:
        chunk = sock.recv(n - len(out))
        if not chunk: raise ConnectionError("connection closed")
        out += chunk
    return out

ERRORS = {0: "Account created on the server.",
          11: "That name is taken on this server.",
          13: "That email is already used on this server.",
          12: "The server does not accept that email provider.",
          23: "Wrong or missing registration key - ask the host for it.",
          1: "The server rejected the name, password or email (letters, numbers, - and _ only).",
          3: "The server rejected the name, password or email (letters, numbers, - and _ only).",
          4: "Too many attempts - wait a minute and try again.",
          24: "The server could not save the account (database error)."}

def create_account(address, npid, password, email, key, timeout=8):
    host, _, port = address.strip().rpartition(":")
    if not host: host, port = port, "31313"
    port = int(port)
    HEADER = 15
    with socket.create_connection((host, port), timeout=timeout) as s:
        s.settimeout(timeout)
        hdr = read_exact(s, HEADER)                       # ServerInfo greeting (type 3)
        if hdr[0] != 3: raise RuntimeError("That address answered, but it is not a shadNet server.")
        size = int.from_bytes(hdr[3:7], "little")
        read_exact(s, size - HEADER)
        proto = bytearray()
        put_string(proto, 1, npid); put_string(proto, 2, password)
        put_string(proto, 4, email); put_string(proto, 5, key)
        pkt = bytearray()
        pkt += b"\x00"                                    # Request
        pkt += (2).to_bytes(2, "little")                  # CommandType::Create
        pkt += (HEADER + 4 + len(proto)).to_bytes(4, "little")
        pkt += (1).to_bytes(8, "little")                  # packet id
        pkt += len(proto).to_bytes(4, "little") + proto
        s.sendall(pkt)
        import time; t0 = time.time()
        while time.time() - t0 < timeout:
            hdr = read_exact(s, HEADER)
            size = int.from_bytes(hdr[3:7], "little")
            payload = read_exact(s, size - HEADER)
            cmd = hdr[1] | (hdr[2] << 8)
            if hdr[0] == 1 and cmd == 2:
                err = payload[0] if payload else 1
                return err == 0, ERRORS.get(err, f"The server refused (error {err}).")
    return False, "No answer from the server."

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--card", help="server card JSON from the host (name, shadnet, registration_key)")
    ap.add_argument("--server", help="host:31313 (overrides the card)")
    ap.add_argument("--key", default="", help="registration key (overrides the card)")
    ap.add_argument("--name", required=True, help="account ID / online name (letters, numbers, - _)")
    ap.add_argument("--password", required=True)
    ap.add_argument("--email", default="", help="default: <name>@shadnet.local")
    ap.add_argument("--user-id", type=int, help="shadPS4 local user id to attach the account to (default: first)")
    ap.add_argument("--no-register", action="store_true", help="skip account creation (already exists)")
    ap.add_argument("--game-server", help="host serving the game API (ss.info on :20443, summons on :31315); default: the shadNet host")
    a = ap.parse_args()

    here = pathlib.Path(__file__).resolve().parent
    user_dir = here / "user" if (here / "user").is_dir() else pathlib.Path(
        os.environ.get("XDG_DATA_HOME") or pathlib.Path.home() / ".local/share") / "shadPS4"
    user_dir.mkdir(parents=True, exist_ok=True)

    server, key = a.server, a.key
    if a.card:
        card = json.load(open(a.card))
        server = server or card.get("shadnet", "")
        key = key or card.get("registration_key", "")
        (user_dir / "servers").mkdir(exist_ok=True)
        shutil.copy(a.card, user_dir / "servers" / pathlib.Path(a.card).name)
    if not server: sys.exit("No server address: give --card or --server")
    email = a.email or f"{a.name}@shadnet.local"

    if not a.no_register:
        print(f"Contacting {server} ...")
        ok, msg = create_account(server, a.name, a.password, email, key)
        print(msg)
        if not ok: sys.exit(1)

    # users.json
    up = user_dir / "users.json"
    users = json.load(open(up)) if up.exists() else {}
    # shadPS4 layout: {"Users": {"commit_hash": ..., "user": [ {...}, ... ]}}
    lst = users.setdefault("Users", {}).setdefault("user", [])
    users.pop("user", None)  # stray top-level list from an older version of this script
    if not lst:
        lst.append({"user_id": 1000, "user_name": "shadPS4", "user_color": 1, "player_index": 1})
    # default: the user on player slot 1 (the one the game logs in as)
    if a.user_id is not None:
        u = next((x for x in lst if x.get("user_id") == a.user_id), None)
    else:
        u = next((x for x in lst if x.get("player_index") == 1), lst[0])
    if u is None: sys.exit(f"No user with id {a.user_id} in {up}")
    u.update({"shadnet_enabled": True, "shadnet_npid": a.name, "shadnet_password": a.password,
              "shadnet_email": email})
    json.dump(users, open(up, "w"), indent=2)
    print(f"users.json: user {u.get('user_id')} ({u.get('user_name')}) uses shadNet account {a.name}")

    # config.json
    cp = user_dir / "config.json"
    cfg = json.load(open(cp)) if cp.exists() else {}
    gen = cfg.setdefault("General", {})
    host = server.rsplit(":", 1)[0]
    gen.update({"shadnet_server": server, "shadnet_webapi_server": f"http://{host}:31315",
                "shad_net_enabled": True, "connected_to_network": True})
    json.dump(cfg, open(cp, "w"), indent=4)
    print(f"config.json: server {server}, network on")

    # host_overrides.json: the game's own server list (Sony's dead ss4.scej-network.jp) and the
    # summon service are redirected to the community game server, as the Windows join-host script does.
    gs = a.game_server or host
    ov = user_dir / "host_overrides.json"
    overrides = json.load(open(ov)) if ov.exists() else {}
    overrides["https://ss4.scej-network.jp:20443"] = f"http://{gs}:20443"
    overrides["http://thehuntersdream.com:18671/summon_messenger"] = f"http://{gs}:31315"
    json.dump(overrides, open(ov, "w"), indent=2)
    print(f"host_overrides.json: game API -> {gs}")
    print("Done. Start the game and choose 'Connect to network'.")

if __name__ == "__main__":
    main()
