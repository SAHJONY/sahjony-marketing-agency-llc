import os, json, hmac, hashlib
from flask import Flask, request, abort
import requests

app = Flask(__name__)

STRIPE_WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET')
CONVEX_DEPLOYMENT_URL = os.getenv('CONVEX_DEPLOYMENT_URL')

def verify_signature(payload: bytes, sig_header: str, secret: str) -> bool:
    # Stripe sends header "t=timestamp,v1=signature". We'll extract v1.
    parts = dict(item.split('=') for item in sig_header.split(','))
    timestamp = parts.get('t')
    signature = parts.get('v1')
    signed_payload = f"{timestamp}.{payload.decode()}".encode()
    expected = hmac.new(secret.encode(), signed_payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)

@app.route('/webhook', methods=['POST'])
def webhook_handler():
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature', '')
    if not STRIPE_WEBHOOK_SECRET or not verify_signature(payload, sig_header, STRIPE_WEBHOOK_SECRET):
        abort(400)
    event = json.loads(payload)
    # Only handle successful checkout sessions for new customers
    if event['type'] == 'checkout.session.completed':
        customer_id = event['data']['object']['customer']
        # Call your internal Convex admin endpoint to create a tenant
        try:
            resp = requests.post(
                f"{CONVEX_DEPLOYMENT_URL}/admin/create-tenant",
                json={"stripe_customer": customer_id},
                timeout=10,
            )
            resp.raise_for_status()
            print('Tenant created for Stripe customer', customer_id)
        except Exception as e:
            print('Error creating tenant:', e)
    return '', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
