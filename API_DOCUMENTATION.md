# GOST Panel REST API Documentation

## Base URL
```
http://localhost:5000/api/v1
```

## Authentication

All endpoints (except `/health` and `/auth/login`) require Bearer token authentication.

### 1. Login (Get Token)

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "username": "admin",
  "password": "admin"
}
```

**Response:**
```json
{
  "token": "a1b2c3d4e5f6...",
  "expires_in": 86400,
  "message": "Authentication successful"
}
```

**Example (curl):**
```bash
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### 2. Logout (Revoke Token)

**Endpoint:** `POST /api/v1/auth/logout`

**Headers:**
```
Authorization: Bearer <your_token>
```

**Response:**
```json
{
  "message": "Token revoked successfully"
}
```

---

## Rules Management

### 1. List All Rules

**Endpoint:** `GET /api/v1/rules`

**Headers:**
```
Authorization: Bearer <your_token>
```

**Response:**
```json
{
  "rules": [
    {
      "id": 1,
      "name": "My SOCKS5 Tunnel",
      "protocol": "socks5",
      "listen": "socks5://:1081",
      "target": "tcp://1.2.3.4:22",
      "password": "",
      "extra": ""
    }
  ],
  "count": 1
}
```

**Example (curl):**
```bash
TOKEN="your_token_here"
curl -X GET http://localhost:5000/api/v1/rules \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Get Specific Rule

**Endpoint:** `GET /api/v1/rules/{id}`

**Headers:**
```
Authorization: Bearer <your_token>
```

**Response:**
```json
{
  "id": 1,
  "name": "My SOCKS5 Tunnel",
  "protocol": "socks5",
  "listen": "socks5://:1081",
  "target": "tcp://1.2.3.4:22",
  "password": "",
  "extra": ""
}
```

**Example (curl):**
```bash
curl -X GET http://localhost:5000/api/v1/rules/1 \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Create New Rule

**Endpoint:** `POST /api/v1/rules`

**Headers:**
```
Authorization: Bearer <your_token>
Content-Type: application/json
```

**Request:**
```json
{
  "name": "My New Tunnel",
  "protocol": "socks5",
  "listen": "socks5://:1082",
  "target": "tcp://5.6.7.8:22",
  "password": "optional_password",
  "extra": "rl=1024"
}
```

**Response:**
```json
{
  "id": 2,
  "message": "Rule created successfully"
}
```

**Example (curl):**
```bash
curl -X POST http://localhost:5000/api/v1/rules \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "API Created Tunnel",
    "protocol": "socks5",
    "listen": "socks5://:1082",
    "target": "tcp://1.2.3.4:22"
  }'
```

### 4. Update Rule

**Endpoint:** `PUT /api/v1/rules/{id}`

**Headers:**
```
Authorization: Bearer <your_token>
Content-Type: application/json
```

**Request (partial update supported):**
```json
{
  "name": "Updated Tunnel Name",
  "listen": "socks5://:1083"
}
```

**Response:**
```json
{
  "message": "Rule updated successfully"
}
```

**Example (curl):**
```bash
curl -X PUT http://localhost:5000/api/v1/rules/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Name"}'
```

### 5. Delete Rule

**Endpoint:** `DELETE /api/v1/rules/{id}`

**Headers:**
```
Authorization: Bearer <your_token>
```

**Response:**
```json
{
  "message": "Rule deleted successfully"
}
```

**Example (curl):**
```bash
curl -X DELETE http://localhost:5000/api/v1/rules/1 \
  -H "Authorization: Bearer $TOKEN"
```

---

## Configuration

### Apply Configuration

**Endpoint:** `POST /api/v1/config/apply`

**Headers:**
```
Authorization: Bearer <your_token>
```

**Response:**
```json
{
  "message": "Configuration applied successfully",
  "note": "Use web UI /apply endpoint for full functionality"
}
```

---

## Health Check

### Check API Status

**Endpoint:** `GET /api/v1/health`

**No authentication required**

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "api": "GOST Panel REST API"
}
```

**Example (curl):**
```bash
curl http://localhost:5000/api/v1/health
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid JSON"
}
```

### 401 Unauthorized
```json
{
  "error": "Invalid or expired token"
}
```

### 404 Not Found
```json
{
  "error": "Rule not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## Complete Workflow Example

### 1. Get Token
```bash
TOKEN=$(curl -s -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' | jq -r '.token')

echo "Token: $TOKEN"
```

### 2. List All Rules
```bash
curl -X GET http://localhost:5000/api/v1/rules \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 3. Create New Rule
```bash
curl -X POST http://localhost:5000/api/v1/rules \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "API Test Tunnel",
    "protocol": "socks5",
    "listen": "socks5://:2080",
    "target": "tcp://example.com:22"
  }' | jq
```

### 4. Update Rule
```bash
curl -X PUT http://localhost:5000/api/v1/rules/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated via API"}' | jq
```

### 5. Delete Rule
```bash
curl -X DELETE http://localhost:5000/api/v1/rules/1 \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 6. Logout
```bash
curl -X POST http://localhost:5000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN" | jq
```

---

## Python Example

```python
import requests

BASE_URL = "http://localhost:5000/api/v1"

# 1. Login
response = requests.post(f"{BASE_URL}/auth/login", json={
    "username": "admin",
    "password": "admin"
})
token = response.json()["token"]
headers = {"Authorization": f"Bearer {token}"}

# 2. List rules
rules = requests.get(f"{BASE_URL}/rules", headers=headers).json()
print(f"Total rules: {rules['count']}")

# 3. Create rule
new_rule = requests.post(f"{BASE_URL}/rules", headers=headers, json={
    "name": "Python API Test",
    "protocol": "socks5",
    "listen": "socks5://:3080",
    "target": "tcp://1.2.3.4:22"
})
rule_id = new_rule.json()["id"]
print(f"Created rule ID: {rule_id}")

# 4. Update rule
requests.put(f"{BASE_URL}/rules/{rule_id}", headers=headers, json={
    "name": "Updated from Python"
})

# 5. Delete rule
requests.delete(f"{BASE_URL}/rules/{rule_id}", headers=headers)

# 6. Logout
requests.post(f"{BASE_URL}/auth/logout", headers=headers)
```

---

## Rate Limiting

Currently no rate limiting is implemented. In production, consider adding rate limiting to prevent abuse.

## Token Expiration

Tokens are valid for 24 hours (86400 seconds). After expiration, you'll need to login again to get a new token.

## Security Notes

- **HTTPS Required:** In production, always use HTTPS to protect tokens in transit
- **Token Storage:** Store tokens securely, never commit them to version control
- **Change Default Password:** Always change the default admin password
- **Firewall:** Restrict API access to trusted IPs if possible
