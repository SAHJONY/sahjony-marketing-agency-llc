import type { NextApiRequest, NextApiResponse } from 'next';
import { execSync } from 'child_process';
import path from 'path';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { prompt, model, provider } = req.body as {
    prompt: string;
    model?: string;
    provider?: string;
  };
  if (!prompt) {
    return res.status(400).json({ error: 'Prompt missing' });
  }

  // Build hermes CLI command. Use environment variables for API keys.
  const args: string[] = [];
  if (provider) args.push('--provider', provider);
  if (model) args.push('--model', model);
  // Ensure hermes writes JSON output for easier parsing.
  args.push('--json');
  args.push('-p', prompt);

  const cmd = ['hermes', 'model', ...args].join(' ');
  try {
    // Run hermes from the project root.
    const cwd = path.resolve(process.cwd(), '..'); // one level up to the repo root
    const output = execSync(cmd, { cwd, env: process.env, encoding: 'utf-8', maxBuffer: 2 * 1024 * 1024 });
    // hermes JSON response typically contains { response: "..." }
    const json = JSON.parse(output);
    return res.status(200).json({ result: json.response ?? json });
  } catch (e: any) {
    return res.status(500).json({ error: 'AI generation failed', details: e.message });
  }
}
