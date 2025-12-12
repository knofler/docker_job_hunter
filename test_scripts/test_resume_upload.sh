#!/bin/bash

# Test resume upload endpoint - works both locally and in Docker
# 
# Usage:
#   Local: ./test_scripts/test_resume_upload.sh
#   Docker: docker compose exec backend bash test_scripts/test_resume_upload.sh
#
# Environment variables (from .env):
#   TEST_RESUMES_PATH: Path to resume files directory
#   API_URL: Backend API endpoint (default: http://localhost:8010)
#   ADMIN_TOKEN: Admin token for authentication

# Load environment from .env if available
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep "^TEST_RESUMES_PATH\|^API_URL\|^ADMIN_TOKEN\|^NEXT_PUBLIC_ADMIN_TOKEN" "$ENV_FILE" 2>/dev/null | xargs)
fi

# Set defaults
RESUMES_PATH="${TEST_RESUMES_PATH:-../sample_files/RESUME}"
API_URL="${API_URL:-http://localhost:8010}"
ADMIN_TOKEN="${ADMIN_TOKEN:-${NEXT_PUBLIC_ADMIN_TOKEN:-changeme-admin-token}}"

# Resolve to absolute path if needed
if [[ "$RESUMES_PATH" = ../* ]]; then
  # Relative path from docker root
  RESUMES_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && cd "$RESUMES_PATH" && pwd 2>/dev/null || echo "$RESUMES_PATH" )"
elif [[ ! "$RESUMES_PATH" = /* ]]; then
  # Try to find it relative to script location
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  RESUMES_PATH="$( cd "$SCRIPT_DIR" && cd "$RESUMES_PATH" && pwd 2>/dev/null || echo "$RESUMES_PATH" )"
fi

# Find resume file
if [ -f "$RESUMES_PATH/RUMMAN AHMED_DevOps.pdf" ]; then
  RESUME_FILE="$RESUMES_PATH/RUMMAN AHMED_DevOps.pdf"
elif [ -d "$RESUMES_PATH" ] && ls "$RESUMES_PATH"/*.pdf 1> /dev/null 2>&1; then
  RESUME_FILE=$(ls "$RESUMES_PATH"/*.pdf | head -1)
else
  echo "❌ Error: Cannot find resume files in $RESUMES_PATH"
  echo "   Please set TEST_RESUMES_PATH in .env or create sample_files/RESUME directory"
  exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Resume Upload Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Resume: $(basename "$RESUME_FILE")"
echo "API: $API_URL/resumes/"
echo "Token: ${ADMIN_TOKEN:0:10}..."
echo ""

# Test 1: candidate_id with type field (new frontend format)
echo -e "${BLUE}[Test 1] Upload with candidate_id + type (NEW frontend)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/resumes/" \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -F "file=@$RESUME_FILE" \
  -F "candidate_id=test-candidate-001" \
  -F "name=Test Resume 1" \
  -F "type=Technical" \
  -F "summary=Test upload with new format")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
  echo -e "${GREEN}✓ Status: $HTTP_CODE Created${NC}"
  echo "Response: $BODY" | head -c 100
  echo "..."
else
  echo -e "${RED}✗ Status: $HTTP_CODE${NC}"
  echo "Response: $BODY"
fi
echo ""

# Test 2: user_id with resume_type field (legacy format)
echo -e "${BLUE}[Test 2] Upload with user_id + resume_type (LEGACY)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/resumes/" \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -F "file=@$RESUME_FILE" \
  -F "user_id=test-user-002" \
  -F "name=Test Resume 2" \
  -F "resume_type=Business" \
  -F "summary=Test upload with legacy format")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
  echo -e "${GREEN}✓ Status: $HTTP_CODE Created${NC}"
  echo "Response: $BODY" | head -c 100
  echo "..."
else
  echo -e "${RED}✗ Status: $HTTP_CODE${NC}"
  echo "Response: $BODY"
fi
echo ""

# Test 3: Mix formats - candidate_id with resume_type
echo -e "${BLUE}[Test 3] Upload with candidate_id + resume_type (MIX)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/resumes/" \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -F "file=@$RESUME_FILE" \
  -F "candidate_id=test-candidate-003" \
  -F "name=Test Resume 3" \
  -F "resume_type=Creative" \
  -F "summary=Test upload with mixed parameter names")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
  echo -e "${GREEN}✓ Status: $HTTP_CODE Created${NC}"
  echo "Response: $BODY" | head -c 100
  echo "..."
else
  echo -e "${RED}✗ Status: $HTTP_CODE${NC}"
  echo "Response: $BODY"
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Tests Complete${NC}"
echo -e "${BLUE}========================================${NC}"
