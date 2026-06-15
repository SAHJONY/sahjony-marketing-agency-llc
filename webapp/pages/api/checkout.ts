import Stripe from 'stripe';
import type { NextApiRequest, NextApiResponse } from 'next';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string, { apiVersion: '2022-11-15' });

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  const { priceId } = req.body;
  if (!priceId) {
    return res.status(400).json({ error: 'Missing priceId' });
  }
  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${process.env.NEXTAUTH_URL}/dashboard?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.NEXTAUTH_URL}/subscribe`,
    });
    return res.status(200).json({ url: session.url });
  } catch (err: any) {
    console.error('Stripe error', err);
    return res.status(500).json({ error: 'Stripe checkout failed' });
  }
}
