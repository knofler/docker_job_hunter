# Test Scripts

Comprehensive testing scripts for the AI Job Hunter API. All scripts support both local development and Docker containerized execution.

## Environment Configuration

Test scripts load configuration from `ai-matching-job-docker/.env`. Key environment variables:

```bash
# Required for authentication
ADMIN_TOKEN=changeme-admin-token

# Optional: Override default test file locations
TEST_RESUMES_PATH=../sample_files/RESUME              # Default: ../sample_files/RESUME
TEST_JDS_PATH=../sample_files/JD                      # Default: ../sample_files/JD
BACKEND_BASE_URL=http://localhost:8010                # Default: http://localhost:8010 (local)
```

### Setting Up Environment Variables

1. **In `ai-matching-job-docker/.env`** (local development):
   ```bash
   ADMIN_TOKEN=changeme-admin-token
   TEST_RESUMES_PATH=../PARTROCK/SAMPLE_RESUMES
   TEST_JDS_PATH=../PARTROCK/SAMPLE_JDS
   BACKEND_BASE_URL=http://localhost:8010
   ```

2. **In Docker Compose** (containerized execution):
   Environment variables are automatically loaded from `.env` file in the docker-compose context.

## Running Tests

### Local Development

From the `ai-matching-job-api` directory:

```bash
# Test resume upload endpoint
./test_scripts/test_resume_upload.sh

# Test job description upload endpoint
./test_scripts/test_jd_upload.sh
```

### Docker Execution

From the `ai-matching-job-docker` directory:

```bash
# Start containers if not already running
docker compose up -d

# Run tests inside the backend container
docker compose exec backend bash test_scripts/test_resume_upload.sh
docker compose exec backend bash test_scripts/test_jd_upload.sh

# Or run from docker compose as a one-off service
docker compose run --rm backend bash test_scripts/test_resume_upload.sh
```

## Test Scripts

### `test_resume_upload.sh`

Tests the `/resumes/` POST endpoint with multiple parameter format variations.

**Purpose:**
- Verify resume file upload functionality
- Test backward compatibility with both `user_id` and `candidate_id` parameters
- Validate HTTP 201 response with resume_id

**Test Scenarios:**

1. **candidate_id + type** (new frontend format)
   ```bash
   curl -F "file=@resume.pdf" \
        -F "candidate_id=candidate123" \
        -F "type=general" \
        http://localhost:8010/resumes/
   ```
   Expected: HTTP 201 with resume_id

2. **user_id + resume_type** (legacy format)
   ```bash
   curl -F "file=@resume.pdf" \
        -F "user_id=user456" \
        -F "resume_type=general" \
        http://localhost:8010/resumes/
   ```
   Expected: HTTP 201 with resume_id

3. **candidate_id + resume_type** (mixed format)
   ```bash
   curl -F "file=@resume.pdf" \
        -F "candidate_id=candidate789" \
        -F "resume_type=general" \
        http://localhost:8010/resumes/
   ```
   Expected: HTTP 201 with resume_id

**Features:**
- ✅ Color-coded output (GREEN ✓ for pass, RED ✗ for fail)
- ✅ Auto-detects resume files in TEST_RESUMES_PATH directory
- ✅ Prioritizes "Rumman Ahmed" resume if available
- ✅ HTTP status code validation
- ✅ Response JSON parsing and display
- ✅ Detailed error reporting

**Output Example:**
```
=== Resume Upload Test Suite ===
Using BACKEND_BASE_URL: http://localhost:8010
Using resume file: ../PARTROCK/SAMPLE_RESUMES/RUMMAN AHMED_DevOps.pdf

Test 1: candidate_id + type
✓ HTTP/1.1 201 Created
✓ Response: {"resume_id":"693b9b79fbf75880a16fab72","message":"Resume uploaded and processed successfully"}

Test 2: user_id + resume_type
✓ HTTP/1.1 201 Created
✓ Response: {"resume_id":"693b9b83fbf75880a16fab75","message":"Resume uploaded and processed successfully"}

Test 3: candidate_id + resume_type
✓ HTTP/1.1 201 Created
✓ Response: {"resume_id":"693b9b8afbf75880a16fab78","message":"Resume uploaded and processed successfully"}

All tests passed! ✓
```

### `test_jd_upload.sh`

Tests the job description upload functionality with multiple format variations.

**Purpose:**
- Verify job description upload functionality
- Test both FormData and JSON request body formats
- Validate recruiter context for job creation

**Test Scenarios:**

1. **FormData Upload**
   ```bash
   curl -F "recruiter_id=recruiter123" \
        -F "title=Senior Software Engineer" \
        -F "description=We are hiring..." \
        http://localhost:8010/jobs/
   ```

2. **JSON Body Upload**
   ```bash
   curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"recruiter_id":"recruiter123","title":"...","description":"..."}' \
        http://localhost:8010/jobs/
   ```

**Features:**
- ✅ Tests both upload formats
- ✅ Uses actual JD files from TEST_JDS_PATH if available
- ✅ Falls back to inline test JD if files not found
- ✅ Colored output for easy result interpretation
- ✅ Detailed error messages on failure

## Environment Variable Resolution

Scripts automatically resolve file paths for both local and Docker execution:

### Local Execution
```bash
# Relative path from current directory
TEST_RESUMES_PATH=../PARTROCK/SAMPLE_RESUMES
# Resolves to: ../PARTROCK/SAMPLE_RESUMES/resume.pdf
```

### Docker Execution
```bash
# Relative path in container context
TEST_RESUMES_PATH=../PARTROCK/SAMPLE_RESUMES
# Container sees this relative to /app (backend working directory)
# Resolves to: /app/../PARTROCK/SAMPLE_RESUMES/resume.pdf
```

## Prerequisites

### Local Development
- Bash shell (zsh/bash)
- curl command-line tool
- Backend API running on `BACKEND_BASE_URL` (default: http://localhost:8010)
- Valid resume/JD files in `TEST_RESUMES_PATH` and `TEST_JDS_PATH`

### Docker Execution
- Docker and Docker Compose installed
- Backend service running via `docker compose up`
- Environment variables in `ai-matching-job-docker/.env`

## Troubleshooting

### Script Fails with "file not found"

**Issue:** Test script cannot find resume/JD files

**Solution:**
1. Check TEST_RESUMES_PATH and TEST_JDS_PATH in `.env`:
   ```bash
   grep TEST_ ../ai-matching-job-docker/.env
   ```

2. Verify files exist:
   ```bash
   ls -la $(cat ../ai-matching-job-docker/.env | grep TEST_RESUMES_PATH | cut -d'=' -f2)
   ```

3. Update .env with correct paths:
   ```bash
   # Local development
   TEST_RESUMES_PATH=../PARTROCK/SAMPLE_RESUMES
   TEST_JDS_PATH=../PARTROCK/SAMPLE_JDS
   
   # Docker - paths relative to /app in container
   ```

### Test Fails with "Connection refused"

**Issue:** Cannot reach backend API

**Solution:**
1. Verify backend is running:
   ```bash
   # Local: should be on http://localhost:8010
   curl http://localhost:8010/health
   
   # Docker: should be accessible from container
   docker compose exec backend curl http://localhost:8010/health
   ```

2. Check BACKEND_BASE_URL in `.env`:
   ```bash
   grep BACKEND_BASE_URL ../ai-matching-job-docker/.env
   ```

3. Restart backend if needed:
   ```bash
   docker compose restart backend
   ```

### Test Returns HTTP 422 (Validation Error)

**Issue:** Missing or invalid request parameters

**Solution:**
- Resume upload requires: `file` and either `user_id` OR `candidate_id`
- Job upload requires: `recruiter_id` (FormData) or full JSON body
- Check parameter names match expected format:
  - ✅ `candidate_id` (new)
  - ✅ `user_id` (legacy)
  - ❌ `candidateId` (camelCase - wrong)

### Docker Test Shows Different Path Behavior

**Issue:** Paths resolve differently in Docker vs local

**Solution:**
- Docker paths are relative to `/app` (backend working directory)
- Use absolute paths or ensure relative paths exist from `/app`:
  ```bash
  # Inside container
  docker compose exec backend pwd     # Shows /app
  docker compose exec backend ls -la ../PARTROCK/SAMPLE_RESUMES
  ```

## Integration with CI/CD

These scripts can be integrated into GitHub Actions or other CI/CD pipelines:

```yaml
# Example GitHub Actions job
- name: Test Resume Upload
  working-directory: ai-matching-job-api
  run: |
    export $(grep -v '^#' ../ai-matching-job-docker/.env | xargs)
    ./test_scripts/test_resume_upload.sh
```

## Adding New Tests

To create a new test script:

1. Copy template structure from existing scripts
2. Load environment variables:
   ```bash
   # Load environment from docker compose context
   if [ -f "../../ai-matching-job-docker/.env" ]; then
       export $(grep -v '^#' ../../ai-matching-job-docker/.env | xargs)
   fi
   ```

3. Use environment variable defaults:
   ```bash
   BACKEND_BASE_URL=${BACKEND_BASE_URL:-http://localhost:8010}
   TEST_RESUMES_PATH=${TEST_RESUMES_PATH:-../sample_files/RESUME}
   ```

4. Add color-coded output for consistency:
   ```bash
   GREEN='\033[0;32m'
   RED='\033[0;31m'
   NC='\033[0m'
   
   echo -e "${GREEN}✓ Test passed${NC}"
   echo -e "${RED}✗ Test failed${NC}"
   ```

## Contributing

When modifying test scripts:
- Keep environment variable loading consistent
- Maintain backward compatibility with existing CI/CD pipelines
- Update this README with any new environment variables or features
- Test both local and Docker execution before committing
- Use color codes for clear output (GREEN ✓, RED ✗)
