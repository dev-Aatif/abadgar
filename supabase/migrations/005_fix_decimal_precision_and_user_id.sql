-- Migration 005: Widen numeric precision and safely enforce user_id when backfilled

-- 1. Match transactions.amount unbounded DECIMAL precision so large PKR harvests
--    or weights never overflow DECIMAL(10,2) (>= 100,000,000.00).
ALTER TABLE public.transactions
  ALTER COLUMN quantity TYPE DECIMAL;

ALTER TABLE public.yield_logs
  ALTER COLUMN total_weight TYPE DECIMAL,
  ALTER COLUMN sale_price TYPE DECIMAL;

-- 2. Enforce NOT NULL on user_id only when no legacy NULL-owned rows remain.
--    If legacy rows exist from migrations 001-003, backfill their user_id first:
--    UPDATE public.seasons SET user_id = '<owner-uuid>' WHERE user_id IS NULL;
--    UPDATE public.transactions SET user_id = '<owner-uuid>' WHERE user_id IS NULL;
--    UPDATE public.yield_logs SET user_id = '<owner-uuid>' WHERE user_id IS NULL;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.seasons WHERE user_id IS NULL) THEN
    ALTER TABLE public.seasons ALTER COLUMN user_id SET NOT NULL;
  ELSE
    RAISE NOTICE 'seasons contains NULL user_id rows; backfill before setting NOT NULL.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.transactions WHERE user_id IS NULL) THEN
    ALTER TABLE public.transactions ALTER COLUMN user_id SET NOT NULL;
  ELSE
    RAISE NOTICE 'transactions contains NULL user_id rows; backfill before setting NOT NULL.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.yield_logs WHERE user_id IS NULL) THEN
    ALTER TABLE public.yield_logs ALTER COLUMN user_id SET NOT NULL;
  ELSE
    RAISE NOTICE 'yield_logs contains NULL user_id rows; backfill before setting NOT NULL.';
  END IF;
END $$;
