-- Migration 003: Add missing columns to yield_logs

ALTER TABLE public.yield_logs
ADD COLUMN disposition TEXT DEFAULT 'Sold',
ADD COLUMN sale_price DECIMAL(10,2) NULL,
ADD COLUMN destination TEXT NULL;
