#!/usr/bin/env bash
# Health check script for Next.js + Supabase projects
# Usage: bash health_check.sh [BASE_URL]
# Default BASE_URL: http://localhost:3000

BASE_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0
WARN=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ PASS${NC}  $1"; ((PASS++)); }
fail() { echo -e "${RED}❌ FAIL${NC}  $1"; ((FAIL++)); }
warn() { echo -e "${YELLOW}⚠️  WARN${NC}  $1"; ((WARN++)); }

check_url() {
  local label="$1"
  local url="$2"
  local expected="${3:-200}"

  local start_ms=$(($(date +%s%N) / 1000000))
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
  local end_ms=$(($(date +%s%N) / 1000000))
  local elapsed=$(( end_ms - start_ms ))

  if [[ "$status" == "$expected" ]]; then
    if (( elapsed > 2000 )); then
      warn "$label → $status (${elapsed}ms — slow)"
    else
      ok "$label → $status (${elapsed}ms)"
    fi
  elif [[ "$status" == "000" ]]; then
    fail "$label → no response (server down or wrong port?)"
  else
    fail "$label → got $status, expected $expected"
  fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Health Check — $BASE_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "── Frontend ──────────────────────────"
check_url "GET /" "$BASE_URL/"

# Check common pages if they exist in the project
for page in "/login" "/dashboard" "/api/health"; do
  # Only check API route always; pages only if a route file exists
  if [[ "$page" == /api/* ]]; then
    check_url "GET $page" "$BASE_URL$page" "200"
  fi
done

echo ""
echo "── API Routes ────────────────────────"

# Auto-detect API routes from project
if command -v find &>/dev/null; then
  routes=$(find . -path "*/app/api/*/route.ts" -o -path "*/pages/api/*.ts" 2>/dev/null | \
    sed 's|.*app/api/||;s|/route\.ts||;s|.*pages/api/||;s|\.ts||' | \
    grep -v '\[' | head -10)

  if [[ -n "$routes" ]]; then
    while IFS= read -r route; do
      check_url "GET /api/$route" "$BASE_URL/api/$route" "200"
    done <<< "$routes"
  else
    warn "No simple API routes found (dynamic routes skipped)"
  fi
fi

echo ""
echo "── Environment Variables ─────────────"

required_vars=(
  "NEXT_PUBLIC_SUPABASE_URL"
  "NEXT_PUBLIC_SUPABASE_ANON_KEY"
)

optional_vars=(
  "SUPABASE_SERVICE_ROLE_KEY"
  "NEXTAUTH_SECRET"
  "NEXTAUTH_URL"
)

env_file=""
for f in .env.local .env .env.production; do
  if [[ -f "$f" ]]; then
    env_file="$f"
    break
  fi
done

if [[ -z "$env_file" ]]; then
  fail "No .env file found (.env.local, .env, .env.production)"
else
  ok "Env file found: $env_file"
  for var in "${required_vars[@]}"; do
    if grep -q "^${var}=" "$env_file" 2>/dev/null || [[ -n "${!var}" ]]; then
      ok "$var is set"
    else
      fail "$var MISSING in $env_file"
    fi
  done
  for var in "${optional_vars[@]}"; do
    if grep -q "^${var}=" "$env_file" 2>/dev/null || [[ -n "${!var}" ]]; then
      ok "$var is set"
    else
      warn "$var not set (optional)"
    fi
  done
fi

echo ""
echo "── Supabase Connectivity ─────────────"

supabase_url=$(grep "^NEXT_PUBLIC_SUPABASE_URL=" "$env_file" 2>/dev/null | cut -d= -f2-)
if [[ -n "$supabase_url" ]]; then
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${supabase_url}/rest/v1/" 2>/dev/null)
  if [[ "$status" == "200" || "$status" == "401" ]]; then
    ok "Supabase REST reachable → $status"
  else
    fail "Supabase REST unreachable → $status (URL: $supabase_url)"
  fi
else
  warn "Cannot ping Supabase — URL not found in env file"
fi

echo ""
echo "── Build Output ──────────────────────"

if [[ -d ".next" ]]; then
  ok ".next/ build output exists"
else
  warn ".next/ not found — run 'next build' for production check"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Results: ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}  ${YELLOW}${WARN} warnings${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if (( FAIL > 0 )); then
  exit 1
fi
exit 0
