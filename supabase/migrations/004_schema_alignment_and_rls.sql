-- Migration 004: Align local & remote schemas, enforce multi-tenant RLS, and add indexes

-- 1. Create missing lands table
CREATE TABLE IF NOT EXISTS public.lands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  area DECIMAL NOT NULL CHECK (area > 0),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 2. Add user_id ownership column to existing tables
ALTER TABLE public.seasons
  ADD COLUMN IF NOT EXISTS user_id UUID DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS user_id UUID DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.yield_logs
  ADD COLUMN IF NOT EXISTS user_id UUID DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS transaction_id UUID NULL REFERENCES public.transactions(id) ON DELETE SET NULL;

-- 3. Align column constraints with offline SQLite schema
ALTER TABLE public.transactions
  ALTER COLUMN category DROP NOT NULL;

ALTER TABLE public.yield_logs
  DROP CONSTRAINT IF EXISTS yield_logs_unit_check;

ALTER TABLE public.yield_logs
  ADD CONSTRAINT yield_logs_unit_check CHECK (unit IN ('Kg', 'Mund (40kg)', 'Tons'));

-- 4. Performance indexes
CREATE INDEX IF NOT EXISTS idx_seasons_user_start ON public.seasons (user_id, start_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_season_date ON public.transactions (season_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_yield_logs_season_date ON public.yield_logs (season_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_yield_logs_user ON public.yield_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_lands_user_name ON public.lands (user_id, name ASC);

-- 5. Enable RLS and replace permissive policies with strict per-user isolation
ALTER TABLE public.seasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yield_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.seasons;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.transactions;
DROP POLICY IF EXISTS "Allow all users to read yield_logs" ON public.yield_logs;
DROP POLICY IF EXISTS "Allow all users to insert yield_logs" ON public.yield_logs;
DROP POLICY IF EXISTS "Allow all users to update yield_logs" ON public.yield_logs;
DROP POLICY IF EXISTS "Allow all users to delete yield_logs" ON public.yield_logs;

CREATE POLICY "Users manage own seasons"
  ON public.seasons FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own transactions"
  ON public.transactions FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own yield_logs"
  ON public.yield_logs FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own lands"
  ON public.lands FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 6. Ensure PowerSync publication includes all synced tables
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'powersync') THEN
    BEGIN
      ALTER PUBLICATION powersync ADD TABLE public.seasons;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION powersync ADD TABLE public.transactions;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION powersync ADD TABLE public.yield_logs;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION powersync ADD TABLE public.lands;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
END $$;
