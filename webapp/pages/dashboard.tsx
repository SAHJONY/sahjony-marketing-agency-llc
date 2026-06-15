import type { GetServerSideProps } from 'next';
import Link from 'next/link';
import { supabase } from '../lib/supabaseClient';

type Site = {
  id: string;
  title: string;
  slug: string;
  description?: string;
  created_at: string;
};

type Props = { sites: Site[] };

export const getServerSideProps: GetServerSideProps = async () => {
  const { data, error } = await supabase.from('sites').select('*');
  if (error) {
    console.error('Supabase fetch error', error);
    return { props: { sites: [] } };
  }
  return { props: { sites: data || [] } };
};

export default function Dashboard({ sites }: Props) {
  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-4">Your Sites</h1>
      {sites.length === 0 ? (
        <p>No sites yet. Create one from the builder.</p>
      ) : (
        <ul className="space-y-4">
          {sites.map((site) => (
            <li key={site.id} className="p-4 border rounded">
              <Link href={`/site/${site.slug}`}>
                <a className="text-xl font-semibold text-primary">{site.title}</a>
              </Link>
              <p className="text-sm text-gray-600">Created {new Date(site.created_at).toLocaleDateString()}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
