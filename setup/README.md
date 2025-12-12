# Setup & Configuration Scripts

Scripts and utilities for setting up the AI Job Hunter application infrastructure.

## Directories

### `auth0/`

Auth0 authentication and role management scripts.

#### Files

- **assign-roles.js**: Script to assign roles to users via Auth0 Management API
  - Usage: Configure Auth0 domain, management API token, and user ID
  - Assigns roles and org_id to users for RBAC

- **auth0-action-sample.js**: Sample Auth0 Post-Login Action
  - Reference implementation for extracting roles from user metadata
  - Adds roles and org_id to JWT claims

- **auth0-action-updated.js**: Updated Auth0 Post-Login Action
  - Production-ready implementation
  - Handles role and org_id assignment during login

- **auth0_test.js**: cURL commands for testing Auth0 Management API
  - Quick reference for API calls
  - Useful for debugging authentication issues

#### Setup Instructions

1. **Get Management API Token**:
   - Go to Auth0 Dashboard > Applications > APIs > Auth0 Management API
   - Click "API Explorer" tab
   - Copy the access token

2. **Update Scripts**:
   - Replace `YOUR_TOKEN_HERE` with your actual management API token
   - Replace `USER_ID` with the target user's ID (found in Auth0 Dashboard > Users)
   - Replace `org_id` with your organization ID

3. **Run assign-roles.js**:
   ```bash
   node assign-roles.js
   ```

4. **Deploy Auth0 Action**:
   - Copy content of auth0-action-updated.js
   - Go to Auth0 Dashboard > Actions > Flows > Post-Login
   - Create new Action and paste the code
   - Attach to your application's Post-Login flow

## Directory Structure

```
setup/
├── README.md                    # This file
└── auth0/
    ├── assign-roles.js          # Role assignment script
    ├── auth0-action-sample.js   # Sample Post-Login Action
    ├── auth0-action-updated.js  # Production Post-Login Action
    └── auth0_test.js            # API testing commands
```

## See Also

- **Test Scripts**: See `../test_scripts/` for API testing
- **Docker Compose**: See `../docker-compose.yml` for service configuration
- **Environment Setup**: See `../.env.example` for configuration variables
