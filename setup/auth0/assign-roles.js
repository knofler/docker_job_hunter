// Auth0 Management API script to assign roles
const axios = require('axios');

async function assignRoles() {
  const AUTH0_DOMAIN = 'myappframe-herokuapp-com.auth0.com';
  const MANAGEMENT_API_TOKEN = 'your-management-api-token'; // Get this from Auth0 Dashboard > APIs > Auth0 Management API > API Explorer
  const USER_ID = 'google-oauth2|102501033367483788758';

  try {
    const response = await axios.patch(
      `https://${AUTH0_DOMAIN}/api/v2/users/${encodeURIComponent(USER_ID)}`,
      {
        app_metadata: {
          roles: ['recruiter'],
          org_id: 'your-org-id'
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${MANAGEMENT_API_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('Roles assigned successfully:', response.data);
  } catch (error) {
    console.error('Error assigning roles:', error.response?.data || error.message);
  }
}

assignRoles();