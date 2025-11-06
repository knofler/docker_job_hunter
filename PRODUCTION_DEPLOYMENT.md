# Production Deployment Checklist

## Vercel (Frontend) Setup

### Environment Variables
Set these in Vercel dashboard under Project Settings > Environment Variables:

```bash
NEXT_PUBLIC_API_URL=https://your-render-app.onrender.com
NEXT_PUBLIC_API_FORCE_REMOTE=1
NEXT_PUBLIC_ADMIN_TOKEN=your-secure-admin-token-here

# Auth0 (if using)
AUTH0_SECRET=your-auth0-secret
AUTH0_BASE_URL=https://your-app.vercel.app
AUTH0_ISSUER_BASE_URL=https://your-tenant.auth0.com
AUTH0_CLIENT_ID=your-auth0-client-id
AUTH0_CLIENT_SECRET=your-auth0-client-secret
AUTH0_AUDIENCE=https://your-render-app.onrender.com
```

### Build Settings
- **Framework Preset**: Next.js
- **Root Directory**: `./` (leave default)
- **Build Command**: `npm run build`
- **Output Directory**: `.next` (leave default)

## Render (Backend) Setup

### Environment Variables
Set these in Render dashboard under Service Settings > Environment:

```bash
MONGO_URI=your-mongodb-connection-string
MONGO_DB_NAME=jobhunter-app
RUN_STARTUP_SEED=false
CORS_ALLOW_ORIGINS=https://your-app.vercel.app
CORS_ALLOW_CREDENTIALS=false
ADMIN_API_KEY=your-secure-admin-token-here
LLM_SETTINGS_SECRET_KEY=your-generated-secret-key

# LLM Provider (choose one)
LLM_DEFAULT_PROVIDER=deepseek
DEEPSEEK_API_KEY=your-deepseek-api-key
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com
```

### Service Configuration
- **Service Type**: Web Service
- **Runtime**: Docker
- **Dockerfile Path**: `./Dockerfile`
- **Port**: 8000 (matches internal port)

## Security Notes

1. **Generate secure tokens**:
   ```bash
   # For LLM_SETTINGS_SECRET_KEY
   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

   # For ADMIN_API_KEY - use a strong random string
   openssl rand -hex 32
   ```

2. **Token consistency**: Ensure `NEXT_PUBLIC_ADMIN_TOKEN` in Vercel matches `ADMIN_API_KEY` in Render

3. **CORS**: Update `CORS_ALLOW_ORIGINS` with your actual Vercel domain

4. **MongoDB**: Use a production MongoDB instance (MongoDB Atlas, etc.)

## Testing Production Deployment

1. **Frontend**: Visit your Vercel URL and check prompts page
2. **API**: Test `https://your-render-app.onrender.com/prompts/` with proper headers
3. **CORS**: Ensure no CORS errors in browser console
4. **Auth**: Verify admin functionality works with production tokens