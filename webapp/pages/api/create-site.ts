import type { NextApiRequest, NextApiResponse } from 'next';
import { supabase } from '../../lib/supabaseClient';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  const { title, slug, description } = req.body;
  if (!title || !slug) {
    return res.status(400).json({ error: 'Missing title or slug' });
  }
  const { data, error } = await supabase.from('sites').insert({
    title,
    slug,
    description,
    created_at: new Date().toISOString(),
  }).single();
  if (error) {
    console.error('Supabase insert error', error);
    return res.status(500).json({ error: 'Database error' });
  }
  // In a real app, you would now invoke the AI generator to build static pages.
  return res.status(201).json({ site: data });
}
