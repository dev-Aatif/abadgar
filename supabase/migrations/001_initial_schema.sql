-- Abadgar Initial Schema

-- Seasons Table
CREATE TABLE seasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  crop_type TEXT NOT NULL, -- 'Rice' | 'Wheat'
  land_area DECIMAL NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL DEFAULT 'Active', -- 'Planned' | 'Active' | 'Completed'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions Table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id UUID REFERENCES seasons(id) ON DELETE CASCADE,
  amount DECIMAL NOT NULL,
  category TEXT NOT NULL,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  type TEXT NOT NULL, -- 'Expense' | 'Revenue'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Realtime / PowerSync Publication
-- Ensure you have a 'powersync' publication or add these tables to it
-- CREATE PUBLICATION powersync FOR TABLE seasons, transactions;

-- Enable RLS (Security)
ALTER TABLE seasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Note: In Part 2 we will add specific RLS policies once Auth is refined.
-- For now, allowing all for testing (NOT FOR PRODUCTION)
CREATE POLICY "Allow all for authenticated users" ON seasons FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated users" ON transactions FOR ALL TO authenticated USING (true);
