#!/bin/bash

# Test Job Description (JD) upload endpoint - works both locally and in Docker
# 
# Usage:
#   Local: ./test_scripts/test_jd_upload.sh
#   Docker: docker compose exec backend bash test_scripts/test_jd_upload.sh
#
# Environment variables (from .env):
#   TEST_JDS_PATH: Path to JD files directory
#   API_URL: Backend API endpoint (default: http://localhost:8010)
#   ADMIN_TOKEN: Admin token for authentication

# Load environment from .env if available
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep "^TEST_JDS_PATH\|^API_URL\|^ADMIN_TOKEN\|^NEXT_PUBLIC_ADMIN_TOKEN" "$ENV_FILE" 2>/dev/null | xargs)
fi

# Set defaults
JDS_PATH="${TEST_JDS_PATH:-../sample_files/JD}"
API_URL="${API_URL:-http://localhost:8010}"
ADMIN_TOKEN="${ADMIN_TOKEN:-${NEXT_PUBLIC_ADMIN_TOKEN:-changeme-admin-token}}"

# Resolve to absolute path if needed
if [[ "$JDS_PATH" = ../* ]]; then
  # Relative path from docker root
  JDS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && cd "$JDS_PATH" && pwd 2>/dev/null || echo "$JDS_PATH" )"
elif [[ ! "$JDS_PATH" = /* ]]; then
  # Try to find it relative to script location
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  JDS_PATH="$( cd "$SCRIPT_DIR" && cd "$JDS_PATH" && pwd 2>/dev/null || echo "$JDS_PATH" )"
fi

# Find JD file
if [ -d "$JDS_PATH" ] && ls "$JDS_PATH"/*.txt 1> /dev/null 2>&1; then
  JD_FILE=$(ls "$JDS_PATH"/*.txt | head -1)
elif [ -d "$JDS_PATH" ] && ls "$JDS_PATH"/*.md 1> /dev/null 2>&1; then
  JD_FILE=$(ls "$JDS_PATH"/*.md | head -1)
else
  # Create a test JD if no files exist
  JD_FILE="/tmp/test_jd.txt"
  cat > "$JD_FILE" << 'EOF'
Senior DevOps Engineer

Location: San Francisco, CA
Experience: 5+ years
Salary: $150,000 - $180,000

Description:
We are looking for an experienced DevOps Engineer to join our infrastructure team.

Key Responsibilities:
- Design and implement CI/CD pipelines
- Manage cloud infrastructure (AWS/GCP/Azure)
- Monitor and optimize system performance
- Lead infrastructure automation initiatives

Required Skills:
- Kubernetes, Docker
- Python, Bash scripting
- CI/CD tools (Jenkins, GitLab CI, GitHub Actions)
- Cloud platforms (AWS preferred)
- Linux system administration

Nice to Have:
- Terraform experience
- Prometheus/Grafana monitoring
- Infrastructure as Code (IaC)
- Previous startup experience
EOF
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Job Description Upload Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo "JD File: $(basename "$JD_FILE")"
echo "API: $API_URL/jobs/upload-jd"
echo "Token: ${ADMIN_TOKEN:0:10}..."
echo ""

# Test 1: Upload via FormData (like frontend)
echo -e "${BLUE}[Test 1] Upload JD as FormData${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/jobs/upload-jd" \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -F "file=@$JD_FILE" \
  -F "recruiter_id=test-recruiter-001" \
  -F "title=Senior DevOps Engineer" \
  -F "description=Cloud infrastructure role")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo -e "${GREEN}✓ Status: $HTTP_CODE${NC}"
  echo "Response: $BODY" | head -c 100
  echo "..."
else
  echo -e "${RED}✗ Status: $HTTP_CODE${NC}"
  echo "Response: $BODY"
fi
echo ""

# Test 2: Upload via JSON body (alternative format)
echo -e "${BLUE}[Test 2] Upload JD as JSON body${NC}"

# Read file content
JD_CONTENT=$(cat "$JD_FILE")

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/jobs/upload-jd" \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Senior DevOps Engineer\",
    \"description\": \"$JD_CONTENT\",
    \"recruiter_id\": \"test-recruiter-002\",
    \"level\": \"Senior\",
    \"salary_band\": \"150k-180k\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo -e "${GREEN}✓ Status: $HTTP_CODE${NC}"
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
echo ""
echo "Note: The /jobs/upload-jd endpoint may require JWT token for some operations."
echo "      For full testing, obtain a valid JWT token from Auth0."
