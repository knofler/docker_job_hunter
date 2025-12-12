/**
 * Handler that will be called during the execution of a PostLogin flow.
 *
 * @param {Event} event - Details about the user and the context in which they are logging in.
 * @param {PostLoginAPI} api - Interface whose methods can be used to change the behavior of the login.
 */
exports.onExecutePostLogin = async (event, api) => {
  // IMPORTANT: Use a custom domain namespace, not the Auth0 tenant domain
  const namespace = 'https://ai-job-hunter/';

  console.log('PostLogin Action triggered for user:', event.user.user_id);
  console.log('User app_metadata:', JSON.stringify(event.user.app_metadata, null, 2));
  console.log('User user_metadata:', JSON.stringify(event.user.user_metadata, null, 2));

  // Get roles from user metadata or app metadata
  const roles = event.user.app_metadata?.roles ||
                event.user.user_metadata?.roles || [];

  // Get organization from user metadata or app metadata
  const org_id = event.user.app_metadata?.org_id ||
                 event.user.user_metadata?.org_id ||
                 event.organization?.id ||
                 'default-org';

  console.log('Extracted roles:', roles);
  console.log('Extracted org_id:', org_id);

  // Add roles to ID token
  if (roles && roles.length > 0) {
    console.log('Setting roles claim:', `${namespace}roles`, roles);
    api.idToken.setCustomClaim(`${namespace}roles`, roles);
  } else {
    console.log('No roles to set');
  }

  // Add organization to ID token
  if (org_id) {
    console.log('Setting org_id claim:', `${namespace}org_id`, org_id);
    api.idToken.setCustomClaim(`${namespace}org_id`, org_id);
  } else {
    console.log('No org_id to set');
  }

  console.log('Action completed');
};
