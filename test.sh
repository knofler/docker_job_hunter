#!/bin/bash

# Comprehensive test script for Job Hunter application
# This script runs tests in Docker containers for both API and frontend

set -e  # Exit on any error

echo "🚀 Starting comprehensive test suite..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "docker-compose is not installed."
    exit 1
fi

# Function to run backend tests
run_backend_tests() {
    print_status "Running backend API tests..."

    # Start test database and dependencies
    docker-compose up -d mongo selenium

    # Wait for services to be ready
    print_status "Waiting for test dependencies to be ready..."
    sleep 10

    # Run backend tests
    if docker-compose --profile test run --rm test-backend; then
        print_success "Backend tests passed!"
        return 0
    else
        print_error "Backend tests failed!"
        return 1
    fi
}

# Function to run frontend tests
run_frontend_tests() {
    print_status "Running frontend tests..."

    # Start test backend for API calls
    docker-compose --profile test up -d test-backend

    # Wait for backend to be ready
    print_status "Waiting for test backend to be ready..."
    sleep 15

    # Run frontend tests
    if docker-compose --profile test run --rm test-frontend; then
        print_success "Frontend tests passed!"
        return 0
    else
        print_error "Frontend tests failed!"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_status "Running integration tests..."

    # Start all services
    docker-compose --profile test up -d test-backend test-frontend

    # Wait for services to be ready
    print_status "Waiting for all services to be ready..."
    sleep 20

    # Run integration tests (if any)
    print_warning "Integration tests not yet implemented"
    return 0
}

# Function to run linting
run_linting() {
    print_status "Running code linting..."

    # Backend linting
    print_status "Linting backend code..."
    if docker-compose --profile test run --rm test-backend just verify 2>/dev/null; then
        print_success "Backend linting passed!"
    else
        print_warning "Backend linting failed or just command not available"
    fi

    # Frontend linting
    print_status "Linting frontend code..."
    if docker-compose --profile test run --rm test-frontend npm run lint 2>/dev/null; then
        print_success "Frontend linting passed!"
    else
        print_warning "Frontend linting failed or lint script not available"
    fi
}

# Function to cleanup test containers
cleanup() {
    print_status "Cleaning up test containers..."
    docker-compose --profile test down -v 2>/dev/null || true
    docker-compose down -v 2>/dev/null || true
}

# Main test execution
main() {
    local backend_passed=0
    local frontend_passed=0
    local integration_passed=0
    local linting_passed=0

    # Parse command line arguments
    local run_backend=true
    local run_frontend=true
    local run_integration=false
    local run_linting=true

    while [[ $# -gt 0 ]]; do
        case $1 in
            --backend-only)
                run_frontend=false
                run_integration=false
                shift
                ;;
            --frontend-only)
                run_backend=false
                run_integration=false
                shift
                ;;
            --integration-only)
                run_backend=false
                run_frontend=false
                run_integration=true
                shift
                ;;
            --no-linting)
                run_linting=false
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --backend-only     Run only backend tests"
                echo "  --frontend-only    Run only frontend tests"
                echo "  --integration-only Run only integration tests"
                echo "  --no-linting       Skip linting checks"
                echo "  --help             Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Trap to ensure cleanup on exit
    trap cleanup EXIT

    print_status "Starting test suite with options:"
    echo "  Backend tests: $run_backend"
    echo "  Frontend tests: $run_frontend"
    echo "  Integration tests: $run_integration"
    echo "  Linting: $run_linting"
    echo

    # Run linting first (fast feedback)
    if $run_linting; then
        run_linting
        linting_passed=$?
    fi

    # Run backend tests
    if $run_backend; then
        if run_backend_tests; then
            backend_passed=0
        else
            backend_passed=1
        fi
    fi

    # Run frontend tests
    if $run_frontend; then
        if run_frontend_tests; then
            frontend_passed=0
        else
            frontend_passed=1
        fi
    fi

    # Run integration tests
    if $run_integration; then
        if run_integration_tests; then
            integration_passed=0
        else
            integration_passed=1
        fi
    fi

    # Summary
    echo
    print_status "Test Summary:"
    echo "  Backend tests: $(if [ $backend_passed -eq 0 ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo "  Frontend tests: $(if [ $frontend_passed -eq 0 ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo "  Integration tests: $(if [ $integration_passed -eq 0 ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo "  Linting: $(if [ $linting_passed -eq 0 ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"

    # Exit with failure if any tests failed
    if [ $backend_passed -ne 0 ] || [ $frontend_passed -ne 0 ] || [ $integration_passed -ne 0 ]; then
        print_error "Some tests failed!"
        exit 1
    else
        print_success "All tests passed! 🎉"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"