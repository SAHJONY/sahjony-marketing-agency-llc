import { useState } from 'react';

export default function AIAgentPage() {
  const [prompt, setPrompt] = useState('');
  const [result, setResult] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    try {
      const res = await fetch('/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt }),
      });
      const data = await res.json();
      if (res.ok) {
        setResult(data.result);
      } else {
        setResult('Error: ' + (data.error || 'unknown'));
      }
    } catch (err) {
      setResult('Fetch error');
    }
    setLoading(false);
  };

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-2xl font-bold mb-4">AI Agentic Generator</h1>
      <form onSubmit={handleSubmit} className="space-y-4">
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Enter your instruction – e.g., generate a landing page for a coffee shop..."
          rows={6}
          className="w-full border rounded p-2"
          required
        />
        <button
          type="submit"
          disabled={loading}
          className="bg-blue-600 text-white py-2 px-4 rounded disabled:opacity-50"
        >
          {loading ? 'Generating…' : 'Generate'}
        </button>
      </form>
      {result && (
        <div className="mt-6 p-4 border rounded bg-gray-50">
          <h2 className="font-semibold mb-2">Result</h2>
          <pre className="whitespace-pre-wrap">{result}</pre>
        </div>
      )}
    </div>
  );
}
