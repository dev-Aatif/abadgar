-- Migration 002: Add Yields and Update Transactions

-- 1. Add new columns to existing transactions table
ALTER TABLE public.transactions
ADD COLUMN quantity DECIMAL(10,2) NULL,
ADD COLUMN buyer_name TEXT NULL;

-- 2. Create yield_logs table
CREATE TABLE public.yield_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    season_id UUID NOT NULL REFERENCES public.seasons(id) ON DELETE CASCADE,
    total_weight DECIMAL(10,2) NOT NULL,
    unit TEXT NOT NULL CHECK (unit IN ('Kg', 'Tons')),
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Enable RLS
ALTER TABLE public.yield_logs ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies for yield_logs
CREATE POLICY "Allow all users to read yield_logs"
ON public.yield_logs FOR SELECT
TO authenticated, anon
USING (true);

CREATE POLICY "Allow all users to insert yield_logs"
ON public.yield_logs FOR INSERT
TO authenticated, anon
WITH CHECK (true);

CREATE POLICY "Allow all users to update yield_logs"
ON public.yield_logs FOR UPDATE
TO authenticated, anon
USING (true);

CREATE POLICY "Allow all users to delete yield_logs"
ON public.yield_logs FOR DELETE
TO authenticated, anon
USING (true);

-- 4. Update the PowerSync publication
ALTER PUBLICATION powersync ADD TABLE public.yield_logs;
