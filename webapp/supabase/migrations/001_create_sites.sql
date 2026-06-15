-- 001_create_sites.sql
-- Supabase table for storing generated sites
CREATE TABLE IF NOT EXISTS public.sites (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable Row Level Security (optional, adjust policies as needed)
ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;

-- Example policy: allow authenticated users to select/insert
CREATE POLICY "allow select" ON public.sites FOR SELECT USING (true);
CREATE POLICY "allow insert" ON public.sites FOR INSERT WITH CHECK (true);
