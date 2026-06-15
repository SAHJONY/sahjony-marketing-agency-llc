import { useState } from 'react';
import { useRouter } from 'next/router';

export default function Builder() {
  const [title, setTitle] = useState('');
  const [slug, setSlug] = useState('');
  const [description, setDescription] = useState('');
  const router = useRouter();
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await fetch('/api/create-site', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, slug, description }),
    });
    if (res.ok) {
      router.push('/dashboard');
    } else {
      const err = await res.json();
      alert('Error: ' + err.error);
    }
  };

  return (
    <div className="max-w-xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">Create a New Site</h1>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block font-medium">Title</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            className="w-full border rounded p-2"
          />
        </div>
        <div>
          <label className="block font-medium">Slug (URL-friendly)</label>
          <input
            type="text"
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
            required
            className="w-full border rounded p-2"
          />
        </div>
        <div>
          <label className="block font-medium">Description (optional)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full border rounded p-2"
          />
        </div>
        <button type="submit" className="bg-primary text-white py-2 px-4 rounded">
          Create Site
        </button>
      </form>
    </div>
  );
}
