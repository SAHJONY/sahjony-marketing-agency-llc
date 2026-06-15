#!/usr/bin/env bash
# ------------------------------------------------------------
# Autonomous Business Setup – one‑click installer for the
# Enterprise Platform Blueprint (SaaS or white‑label mode).
# ------------------------------------------------------------
set -euo pipefail

# ---- CONFIGURATION ------------------------------------------------
# Edit these variables before running the script if you need custom values.
export DEPLOY_MODE="saas"               # "saas" (hosted) or "white_label"
export DOMAIN="example.com"             # your public domain (used for Stripe webhook verification)
export STRIPE_SECRET_KEY=***   # Stripe secret key (live key for production)
export STRIPE_WEBHOOK_SECRET=*** # Stripe webhook signing secret
export CONVEX_DEPLOYMENT="production"   # Convex deployment name (or leave empty for dev)
export DOCKER_REGISTRY="docker.io/yourorg" # where to push the Daytona image
export VERCEL_PROJECT_ID=""            # Vercel project ID (set to enable Vercel deployment)
export VERCEL_TOKEN=***                # Vercel token for non-interactive auth (optional)
# -------------------------------------------------------------------

# ---- AUTOMATIC .env AND VERCEL ENV SETUP --------------------------
# If a .env file does not exist, create one using the variables above.
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<EOF
DEPLOY_MODE=${DEPLOY_MODE}
DOMAIN=${DOMAIN}
STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
CONVEX_DEPLOYMENT=
DOCKER_REGISTRY=${DOCKER_REGISTRY}
VERCEL_PROJECT_ID=${VERCEL_PROJECT_ID}
VERCEL_TOKEN=${VERCEL_TOKEN}
BRAND_NAME="SAHJONY MARKETING AGENCY LLC"
EOF
  echo ".env file generated with provided configuration."
else
  echo ".env already exists – using existing values."
fi

# If Vercel CLI is available and a project ID is set, push the env vars to Vercel.
if command -v vercel &>/dev/null && [ -n "$VERCEL_PROJECT_ID" ]; then
  echo "Uploading environment variables to Vercel project $VERCEL_PROJECT_ID..."
  vercel env add DEPLOY_MODE "$DEPLOY_MODE" --project "$VERCEL_PROJECT_ID" ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"} --yes
  vercel env add DOMAIN "$DOMAIN" --project "$VERCEL_PROJECT_ID" ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"} --yes
  vercel env add STRIPE_SECRET_KEY "$STRIPE_SECRET_KEY" --project "$VERCEL_PROJECT_ID" ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"} --yes
  vercel env add STRIPE_WEBHOOK_SECRET "$STRIPE_WEBHOOK_SECRET" --project "$VERCEL_PROJECT_ID" ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"} --yes
  vercel env add CONVEX_DEPLOYMENT "$CONVEX_DEPLOYMENT" --project "$VERCEL_PROJECT_ID" ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"} --yes
  vercel env add DOCKER_REGISTRY "$DOCKER_REGISTRY" --project "$VERCEL_PROJECT_ID" ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"} --yes
fi

# Helper to print sections nicely
section() {
  echo -e "\n===== $1 =====\n"
}

# 1️⃣ Install system dependencies (Docker, Node, npm, netlify-cli)
section "Installing system dependencies"
if ! command -v docker &>/dev/null; then
  echo "Docker not found – installing Docker CE…"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm get-docker.sh
fi

if ! command -v node &>/dev/null; then
  echo "Node not found – installing via nvm…"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \source "$NVM_DIR/nvm.sh"
  nvm install --lts
fi

if ! command -v netlify &>/dev/null; then
  echo "Installing Netlify CLI globally…"
  npm install -g netlify-cli
fi

# 2️⃣ Build and push Daytona Docker image
section "Building and pushing Daytona image"
# ----- Build and push Daytona Docker image (optional) -----
ios_dir=$(dirname "$0")/../ios
if [ -d "$ios_dir" ] && [ -f "$ios_dir/Dockerfile" ]; then
  echo "Building Daytona image from $ios_dir/Dockerfile"
  cd "$ios_dir"
  IMAGE_TAG="${DOCKER_REGISTRY}/daytona:${DEPLOY_MODE}-$(date +%s)"
  docker build -t "$IMAGE_TAG" .
  docker push "$IMAGE_TAG"
  echo "Daytona image pushed: $IMAGE_TAG"
else
  echo "Skipping Daytona image build – iOS directory or Dockerfile not found."
fi

# 3️⃣ Deploy Convex (if in SaaS mode)
section "Deploying Convex"
if [ "$DEPLOY_MODE" = "saas" ]; then
  if [ -z "${CONVEX_DEPLOYMENT}" ]; then
    echo "Skipping Convex deployment – no deployment name provided."
  else
    npx convex deploy
    echo "Convex deployed to $CONVEX_DEPLOYMENT"
  fi
fi

# 4️⃣ Install Node dependencies and start API
section "Starting Node API"
cd $(dirname "$0")/../api
npm ci
# Create .env for the API
cat > .env <<EOF
STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
CONVEX_DEPLOYMENT_URL=${CONVEX_DEPLOYMENT}
EOF
# Run API in background (detached Docker container for production)
if [ "$DEPLOY_MODE" = "saas" ]; then
  docker build -t enterprise-api .
  docker run -d \
    --name enterprise-api \
    -p 8080:8080 \
    --env-file .env \
    enterprise-api
else
  echo "Running API locally for white‑label mode…"
  npm start &
fi

# 0️⃣ Generate marketing site from template
section "Generating marketing site from template"
bash "$(dirname "$0")/generate_site_from_template.sh"

# 5️⃣ Deploy marketing site to Vercel (optional)
section "Deploying marketing site"
cd $(dirname "$0")/../site
if command -v vercel &>/dev/null && [ -n "$VERCEL_PROJECT_ID" ]; then
  vercel --prod --confirm --cwd . --token "$VERCEL_TOKEN" --project "$VERCEL_PROJECT_ID"
else
  echo "VERCEL_PROJECT_ID not set – you can run 'vercel link' manually inside the site folder, then re‑run this script."
fi

# 6️⃣ Create Stripe products & prices (run once)
section "Creating Stripe products"
node - <<'NODE'
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
(async () => {
  const products = [
    {name: 'Starter', description: 'Responsive layouts, community support'},
    {name: 'Pro', description: 'Custom CI/CD, 5GB bandwidth, priority support'},
    {name: 'Enterprise', description: 'Dedicated cluster, unlimited bandwidth, SLA'}
  ];
  for (const p of products) {
    const prod = await stripe.products.create({name: p.name, description: p.description});
    await stripe.prices.create({unit_amount: p.name === 'Starter' ? 0 : 0, // placeholder – will be updated by pricing service
      currency: 'usd', recurring: {interval: 'month'}, product: prod.id});
    console.log(`Created ${p.name} product ${prod.id}`);
  }
})();
NODE

# 7️⃣ Set up Stripe webhook endpoint (writes a tiny Flask app and starts it)
section "Setting up Stripe webhook handler"
cd $(dirname "$0")/../scripts
cat > stripe_webhook_handler.py <<'PY'
import os, json, hmac, hashlib
from flask import Flask, request, abort
import requests
app = Flask(__name__)
STRIPE_SECRET = os.getenv('STRIPE_SECRET_KEY')
WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET')
CONVEX_URL = os.getenv('CONVEX_DEPLOYMENT_URL')

def verify_signature(payload, sig_header, secret):
    signed_payload = f'timestamp={request.headers.get("Stripe-Signature-TS", "")}.' + payload
    expected = hmac.new(secret.encode(), signed_payload.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, sig_header)

@app.route('/webhook', methods=['POST'])
def webhook():
    payload = request.data.decode('utf-8')
    sig = request.headers.get('Stripe-Signature')
    if not verify_signature(payload, sig, WEBHOOK_SECRET):
        abort(400)
    event = json.loads(payload)
    if event['type'] == 'checkout.session.completed':
        customer = event['data']['object']['customer']
        # Create a Convex tenant (call your API endpoint)
        import requests
        resp = requests.post(f"{CONVEX_URL}/admin/create-tenant", json={"stripe_customer": customer})
        print('Tenant creation response:', resp.text)
    return '', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PY

# Run the webhook handler in background (Docker container for prod)
if [ "$DEPLOY_MODE" = "saas" ]; then
  docker build -t stripe-webhook - <<EOF
FROM python:3.12-slim
WORKDIR /app
COPY stripe_webhook_handler.py .
RUN pip install Flask requests
EXPOSE 5000
CMD ["python", "stripe_webhook_handler.py"]
EOF
  docker run -d --name stripe-webhook \
    -p 5000:5000 \
    -e STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY \
    -e STRIPE_WEBHOOK_SECRET=$STRIPE_WEBHOOK_SECRET \
    -e CONVEX_DEPLOYMENT_URL=$CONVEX_DEPLOYMENT \
    stripe-webhook
fi

# 8️⃣ Install profit‑tracking cron job (Hermes)
section "Installing profit‑tracking cron job"
hermes cronjob action='create' \
  name='daily-profit-tracker' \
  schedule='0 2 * * *' \
  prompt='python3 /home/juangonzalez/enterprise-platform/scripts/profit_tracker.py' \
  deliver='origin' \
  enabled_toolsets=['file','web']

section "Setup complete"
echo "Your autonomous SaaS platform is now running."
echo "- Marketing site: <your‑vercel‑url>"
 echo "- API endpoint: http://$(hostname -I | awk '{print $1}'):8080"
 echo "- Stripe webhook listening on port 5000 (exposed via Docker)"
