# OpenVPN AS with Admin Bootstrap

Wrapper image around the official **OpenVPN Access Server** that automatically creates an admin user from environment variables on startup.

## 🚀 Quick start

### 1. Create `.env`

```env
OPENVPN_ADMIN_USERNAME=admin
OPENVPN_ADMIN_PASSWORD=supersecurepassword
```

### 2. Run

```bash
docker run -d \
  --name openvpn \
  --restart unless-stopped \
  --cap-add=NET_ADMIN \
  --cap-add=MKNOD \
  --device /dev/net/tun:/dev/net/tun \
  -p 943:943 \
  -p 1194:1194/udp \
  -p 443:443/tcp \
  --env-file .env \
  -v /path/to/openvpn-data:/openvpn \
  --sysctl net.ipv4.ip_forward=1 \
  ghcr.io/kalpak44/openvpn-as-with-admin-bootstrap:latest
```

### 3. Open UI

```text
https://<host>:943/admin
```

Login with:

```text
admin / (password from .env)
```


## ⚙️ Env vars

| Variable               | Default | Description    |
| ---------------------- | ------- | -------------- |
| OPENVPN_ADMIN_USERNAME | admin   | Admin username |
| OPENVPN_ADMIN_PASSWORD | —       | Admin password |
| OPENVPN_BOOTSTRAP_ONCE | true    | Run only once  |


## 🔁 Reset bootstrap

```bash
docker exec -it openvpn rm -f /openvpn/etc/admin_user_bootstrapped
docker restart openvpn
```

## 🧠 Notes

* Wraps the official OpenVPN Access Server image (no changes to core behavior)
* Admin user is created automatically via `sacli`
* No hardcoded IPs — use your host or DNS
* `/openvpn` volume is required for persistence

