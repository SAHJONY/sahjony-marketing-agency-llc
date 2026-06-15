import { useState } from 'react';

export default function SubscribeButton({ priceId }: { priceId: string }) {
  const [loading, setLoading] = useState(false);
  const handleClick = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ priceId }),
      });
      const data = await res.json();
      if (data.url) {
        window.location.href = data.url;
      } else {
        alert('Checkout error: ' + (data.error || 'unknown'));
      }
    } catch (e) {
      alert('Network error');
    }
    setLoading(false);
  };
  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className="bg-indigo-600 text-white py-2 px-4 rounded disabled:opacity-50"
    >
      {loading ? 'Processing…' : 'Subscribe'}
    </button>
  );
}
