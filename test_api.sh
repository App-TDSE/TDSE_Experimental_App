#!/usr/bin/env bash
# =============================================================================
# TDSE API Test Suite
# Tests public endpoints, JWT validation, protected endpoints, and error cases.
# Requires: curl, jq
#
# Usage:
#   ./test_api.sh                        # uses defaults from .env.test
#   ./test_api.sh --token <jwt>          # skip Auth0 token fetch, use provided token
#   ./test_api.sh --api-url http://...   # override API base URL
# =============================================================================

set -uo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# ─── Counters ─────────────────────────────────────────────────────────────────
PASSED=0
FAILED=0

# ─── Defaults (overridden by .env.test or CLI flags) ──────────────────────────
API_URL="http://localhost:8080"
AUTH0_DOMAIN=""
AUTH0_CLIENT_ID=""
AUTH0_CLIENT_SECRET=""
AUTH0_AUDIENCE=""
MANUAL_TOKEN=""

# ─── Load .env.test if present ────────────────────────────────────────────────
if [[ -f ".env.test" ]]; then
  echo -e "${CYAN}Loading .env.test...${RESET}"
  set -o allexport
  # shellcheck disable=SC1091
  source .env.test
  set +o allexport
fi

# ─── CLI argument overrides ───────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)       MANUAL_TOKEN="$2";  shift 2 ;;
    --api-url)     API_URL="$2";       shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────
section() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${CYAN}  $1${RESET}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# assert_status <label> <expected_status> <actual_status> [response_body]
assert_status() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local body="${4:-}"

  if [[ "$actual" == "$expected" ]]; then
    echo -e "  ${GREEN}✅ PASS${RESET}  ${label} → HTTP $actual"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}❌ FAIL${RESET}  ${label} → expected HTTP $expected, got HTTP $actual"
    if [[ -n "$body" ]]; then
      echo -e "         ${YELLOW}Response: $(echo "$body" | head -c 300)${RESET}"
    fi
    FAILED=$((FAILED + 1))
  fi
}

# assert_json_field <label> <field_path> <expected_value> <json_body>
assert_json_field() {
  local label="$1"
  local field="$2"
  local expected="$3"
  local body="$4"

  local actual
  actual=$(echo "$body" | jq -r "$field" 2>/dev/null || echo "")

  if [[ "$actual" == "$expected" ]]; then
    echo -e "  ${GREEN}✅ PASS${RESET}  ${label} → field '$field' = '$actual'"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}❌ FAIL${RESET}  ${label} → field '$field': expected '$expected', got '$actual'"
    FAILED=$((FAILED + 1))
  fi
}

# http <method> <path> [extra curl args...]
# Returns "<status_code> <body>" separated by a newline
http() {
  local method="$1"
  local path="$2"
  shift 2

  local response
  response=$(curl -s -w "\n%{http_code}" -X "$method" "${API_URL}${path}" "$@")

  local status
  status=$(echo "$response" | tail -n 1)
  local body
  body=$(echo "$response" | awk 'NR>1{print prev} {prev=$0}')

  echo "$status"$'\n'"$body"
}

# ─── Prerequisites ─────────────────────────────────────────────────────────────
section "Prerequisites"

# Check curl
if ! command -v curl &>/dev/null; then
  echo -e "  ${RED}✗ curl not found. Install curl to run this script.${RESET}"
  exit 1
fi
echo -e "  ${GREEN}✓${RESET} curl found"

# Check jq
if ! command -v jq &>/dev/null; then
  echo -e "  ${RED}✗ jq not found. Install jq to run this script (brew install jq / apt install jq).${RESET}"
  exit 1
fi
echo -e "  ${GREEN}✓${RESET} jq found"

# Check backend reachability
echo -e "  Checking backend at ${API_URL}..."
if ! curl -s --max-time 5 "${API_URL}/actuator/health" > /dev/null 2>&1 && \
   ! curl -s --max-time 5 "${API_URL}/api/posts" > /dev/null 2>&1; then
  echo -e "  ${RED}✗ Backend not reachable at ${API_URL}. Is the server running?${RESET}"
  exit 1
fi
echo -e "  ${GREEN}✓${RESET} Backend reachable at ${API_URL}"

# ─── Token acquisition ────────────────────────────────────────────────────────
section "Token Acquisition"

TOKEN=""

if [[ -n "$MANUAL_TOKEN" ]]; then
  TOKEN="$MANUAL_TOKEN"
  echo -e "  ${GREEN}✓${RESET} Using manually provided token (--token flag)"

elif [[ -n "$AUTH0_DOMAIN" && -n "$AUTH0_CLIENT_ID" && -n "$AUTH0_CLIENT_SECRET" && -n "$AUTH0_AUDIENCE" ]]; then
  echo -e "  Fetching M2M token from Auth0 (${AUTH0_DOMAIN})..."

  TOKEN_RESPONSE=$(curl -s --request POST \
    --url "https://${AUTH0_DOMAIN}/oauth/token" \
    --header "content-type: application/json" \
    --data "{
      \"client_id\": \"${AUTH0_CLIENT_ID}\",
      \"client_secret\": \"${AUTH0_CLIENT_SECRET}\",
      \"audience\": \"${AUTH0_AUDIENCE}\",
      \"grant_type\": \"client_credentials\"
    }")

  TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')

  if [[ -z "$TOKEN" ]]; then
    ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // .error // "Unknown error"')
    echo -e "  ${RED}✗ Failed to fetch token from Auth0: ${ERROR}${RESET}"
    echo -e "  ${YELLOW}Protected endpoint tests will be skipped.${RESET}"
  else
    echo -e "  ${GREEN}✓${RESET} Token acquired from Auth0"
    echo -e "  ${CYAN}  Token preview: ${TOKEN:0:40}...${RESET}"
  fi

else
  echo -e "  ${YELLOW}⚠ No Auth0 credentials found in .env.test and no --token provided.${RESET}"
  echo -e "  ${YELLOW}  Protected endpoint tests will be skipped.${RESET}"
  echo -e "  ${YELLOW}  To enable them, create a .env.test file — see .env.test.example.${RESET}"
fi

# ─── Test 1: Public Endpoints ─────────────────────────────────────────────────
section "1. Public Endpoints (no token required)"

# GET /api/posts
result=$(http GET "/api/posts")
status=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)
assert_status "GET /api/posts returns 200" "200" "$status" "$body"

# GET /api/stream
result=$(http GET "/api/stream")
status=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)
assert_status "GET /api/stream returns 200" "200" "$status" "$body"

# Verify responses are JSON arrays (not error objects)
result=$(http GET "/api/posts")
body=$(echo "$result" | tail -n +2)
if echo "$body" | jq -e 'if type == "array" then true elif .content then true else false end' > /dev/null 2>&1; then
  echo -e "  ${GREEN}✅ PASS${RESET}  GET /api/posts returns a JSON list"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}❌ FAIL${RESET}  GET /api/posts did not return a JSON list — got: $(echo "$body" | head -c 200)"
  FAILED=$((FAILED + 1))
fi

# ─── Test 2: Unauthenticated Access to Protected Endpoints ────────────────────
section "2. Protected Endpoints — No Token (expect 401)"

result=$(http GET "/api/me")
status=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)
assert_status "GET /api/me without token → 401" "401" "$status" "$body"

result=$(http POST "/api/posts" \
  -H "Content-Type: application/json" \
  -d '{"content":"Unauthorized post attempt"}')
status=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)
assert_status "POST /api/posts without token → 401" "401" "$status" "$body"

# ─── Test 3: Invalid / Malformed Token ────────────────────────────────────────
section "3. Invalid Token Handling (expect 401)"

result=$(http GET "/api/me" -H "Authorization: Bearer this.is.not.a.jwt")
status=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)
assert_status "GET /api/me with garbage token → 401" "401" "$status" "$body"

# A structurally valid but tampered JWT (header.payload.bad_signature)
FAKE_JWT="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmYWtlIiwiYXVkIjoiaHR0cHM6Ly90ZHNlYXBwLmFwaSIsImlzcyI6Imh0dHBzOi8vZmFrZS5hdXRoMC5jb20vIn0.invalidsignature"
result=$(http GET "/api/me" -H "Authorization: Bearer $FAKE_JWT")
status=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)
assert_status "GET /api/me with invalid signature → 401" "401" "$status" "$body"

# ─── Test 4: Protected Endpoints With Valid Token ─────────────────────────────
if [[ -n "$TOKEN" ]]; then
  section "4. Protected Endpoints — Valid Token"

  # GET /api/me
  result=$(http GET "/api/me" -H "Authorization: Bearer $TOKEN")
  status=$(echo "$result" | head -1)
  body=$(echo "$result" | tail -n +2)
  assert_status "GET /api/me with valid token → 200" "200" "$status" "$body"

  # Verify user object shape
  if [[ "$status" == "200" ]]; then
    if echo "$body" | jq -e '.userId // .id' > /dev/null 2>&1; then
      echo -e "  ${GREEN}✅ PASS${RESET}  /api/me response contains user identifier field"
      PASSED=$((PASSED + 1))
    else
      echo -e "  ${RED}❌ FAIL${RESET}  /api/me response missing 'userId'/'id' field — got: $(echo "$body" | head -c 200)"
      FAILED=$((FAILED + 1))
    fi
  fi

  # POST /api/posts — valid content
  POST_CONTENT="Test post from automated suite $(date +%s)"
  result=$(http POST "/api/posts" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"${POST_CONTENT}\"}")
  status=$(echo "$result" | head -1)
  body=$(echo "$result" | tail -n +2)
  assert_status "POST /api/posts with valid token → 201" "201" "$status" "$body"

  # Verify the new post appears in the feed
  if [[ "$status" == "201" ]]; then
    sleep 1
    result=$(http GET "/api/posts")
    feed_body=$(echo "$result" | tail -n +2)
    if echo "$feed_body" | jq -e --arg c "$POST_CONTENT" \
      'if type == "array" then any(.[]; .content == $c)
       else any(.content[]?; .content == $c) end' > /dev/null 2>&1; then
      echo -e "  ${GREEN}✅ PASS${RESET}  New post appears in GET /api/posts feed"
      PASSED=$((PASSED + 1))
    else
      echo -e "  ${YELLOW}⚠ INFO${RESET}   Could not confirm post in feed (pagination may hide it)"
    fi
  fi

  # ─── Test 5: Business Rule — 140 Character Limit ──────────────────────────
  section "5. Business Rules"

  LONG_POST=$(python3 -c "print('x' * 141)")
  result=$(http POST "/api/posts" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"${LONG_POST}\"}")
  status=$(echo "$result" | head -1)
  body=$(echo "$result" | tail -n +2)
  assert_status "POST /api/posts with 141-char content → 400" "400" "$status" "$body"

  EXACT_POST=$(python3 -c "print('x' * 140)")
  result=$(http POST "/api/posts" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"${EXACT_POST}\"}")
  status=$(echo "$result" | head -1)
  body=$(echo "$result" | tail -n +2)
  assert_status "POST /api/posts with exactly 140 chars → 201" "201" "$status" "$body"

  EMPTY_POST=""
  result=$(http POST "/api/posts" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"content":""}')
  status=$(echo "$result" | head -1)
  body=$(echo "$result" | tail -n +2)
  assert_status "POST /api/posts with empty content → 400" "400" "$status" "$body"

else
  echo ""
  echo -e "  ${YELLOW}⚠ Skipping Tests 4 & 5 — no valid token available.${RESET}"
  echo -e "  ${YELLOW}  See .env.test.example to configure Auth0 M2M credentials.${RESET}"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Test Summary${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${GREEN}Passed: ${PASSED}${RESET}"
echo -e "  ${RED}Failed: ${FAILED}${RESET}"
TOTAL=$((PASSED + FAILED))
echo -e "  Total:  ${TOTAL}"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}All tests passed. ✓${RESET}"
  exit 0
else
  echo -e "  ${RED}${BOLD}Some tests failed. See output above.${RESET}"
  exit 1
fi