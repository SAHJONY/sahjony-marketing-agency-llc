import type { GetServerSideProps } from 'next';
import { supabase } from '../lib/supabaseClient';

type Site = { id: string; title: string; slug: string; description?: string; created_at: string };

type Props = { sites: Site[] };

export const getServerSideProps: GetServerSideProps = async () => {
  const { data, error } = await supabase.from('sites').select('*');
  if (error) {
    console.error('Supabase fetch error', error);
    return { props: { sites: [] } };
  }
  return { props: { sites: data || [] } };
};

export default function Admin({ sites }: Props) {
  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">Admin Dashboard</h1>
      <p className="mb-4">Total sites: {sites.length}</p>
      <ul className="space-y-2">
        {sites.map((site) => (
          <li key={site.id} className="p-3 border rounded">
            <strong>{site.title}</strong> (/{site.slug}) – Created {new Date(site.created_at).toLocaleDateString()}
          </li>
        ))}
      </ul>
    </div>
  );
}
