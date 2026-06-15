import os, json, datetime
import stripe
import requests

# Environment variables – set in cron job or .env
STRIPE_SECRET = os.getenv('STRIPE_SECRET_KEY')
CONVEX_URL = os.getenv('CONVEX_DEPLOYMENT_URL')
REPORT_DIR = os.path.expanduser('~/profit_reports')
os.makedirs(REPORT_DIR, exist_ok=True)

stripe.api_key = STRIPE_SECRET

def fetch_stripe_mrr():
    # Pull all active subscriptions and sum their monthly amount (in cents)
    if not STRIPE_SECRET or STRIPE_SECRET == '***':
        print('Stripe API key missing or masked – skipping Stripe MRR fetch')
        return 0
    total = 0
    for sub in stripe.Subscription.list(status='active', limit=100):
        for item in sub['items']['data']:
            total += item['plan']['amount']
    return total / 100  # dollars

def fetch_convex_usage():
    # Assume you have an endpoint that returns usage minutes per org in the last 30 days
    try:
        resp = requests.get(f"{CONVEX_URL}/admin/usage-summary", timeout=10)
        resp.raise_for_status()
        data = resp.json()  # {orgId: {minutes: N, cost_per_minute: 0.02}}
        return data
    except Exception as e:
        print('Error fetching Convex usage:', e)
        return {}

def compute_profit():
    mrr = fetch_stripe_mrr()
    usage = fetch_convex_usage()
    total_cost = sum(v['minutes'] * v.get('cost_per_minute', 0.02) for v in usage.values())
    profit = mrr - total_cost
    return {
        'date': datetime.datetime.utcnow().isoformat() + 'Z',
        'mrr_usd': mrr,
        'total_cost_usd': total_cost,
        'profit_usd': profit,
        'orgs': usage,
    }

if __name__ == '__main__':
    report = compute_profit()
    out_path = os.path.join(REPORT_DIR, 'latest.json')
    with open(out_path, 'w') as f:
        json.dump(report, f, indent=2)
    print('Profit report written to', out_path)
    # Optional: Send a Slack webhook if profit is negative
    if report['profit_usd'] < 0:
        webhook = os.getenv('SLACK_WEBHOOK')
        if webhook:
            requests.post(webhook, json={'text': f"⚠️ Negative profit today: ${report['profit_usd']:.2f}"})
