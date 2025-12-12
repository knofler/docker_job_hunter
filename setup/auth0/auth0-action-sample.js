/**
 * Handler that will be called during the execution of a PostLogin flow.
 *
 * @param {Event} event - Details about the user and the context in which they are logging in.
 * @param {PostLoginAPI} api - Interface whose methods can be used to change the behavior of the login.
 */
exports.onExecutePostLogin = async (event, api) => {
  console.log('Auth0 Action executing for user:', event.user.sub);

  // IMPORTANT: Namespace must match what the frontend expects
  // Frontend checks for: https://myappframe-herokuapp-com.auth0.com/roles (with trailing slash)
  const namespace = 'https://myappframe-herokuapp-com.auth0.com/';

  // Get roles from user metadata or app metadata
  // This is where you should store user roles in Auth0
  const roles = event.user.app_metadata?.roles ||
                event.user.user_metadata?.roles || [];

  const org_id = event.user.app_metadata?.org_id ||
                 event.user.user_metadata?.org_id ||
                 event.organization?.id ||
                 'default-org';

  console.log('Found roles:', roles);
  console.log('Found org_id:', org_id);
  console.log('App metadata:', JSON.stringify(event.user.app_metadata, null, 2));

  // Add roles to ID token (this is what the frontend reads)
  if (roles && roles.length > 0) {
    console.log('Adding roles to ID token:', `${namespace}roles`, roles);
    api.idToken.setCustomClaim(`${namespace}roles`, roles);
  } else {
    console.log('No roles found, not adding to ID token');
  }

  // Add organization to ID token
  if (org_id) {
    console.log('Adding org_id to ID token:', `${namespace}org_id`, org_id);
    api.idToken.setCustomClaim(`${namespace}org_id`, org_id);
  }

  console.log('Auth0 Action completed');
};