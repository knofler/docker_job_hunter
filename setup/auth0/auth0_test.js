curl -X PATCH "https://myappframe-herokuapp-com.auth0.com/api/v2/users/google-oauth2%7C102501033367483788758" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "app_metadata": {
      "roles": ["recruiter"],
      "org_id": "your-org-id"
    }
  }'