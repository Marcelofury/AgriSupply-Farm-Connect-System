-- ============================================
-- Manual Fix: RLS + Remaining Compatibility
-- ============================================
-- Run in Supabase SQL Editor after manual_fix_checkout_payment.sql
-- ============================================

BEGIN;

-- 1) Add legacy payment columns used by some mobile service paths
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS provider VARCHAR(50),
  ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);

-- 2) Keep aliases synchronized where possible
UPDATE public.payments
SET
  provider = COALESCE(provider, method, payment_method),
  transaction_id = COALESCE(transaction_id, transaction_ref, provider_transaction_id)
WHERE provider IS NULL OR transaction_id IS NULL;

-- 3) Ensure order_status_history accepts both old/new field names
ALTER TABLE public.order_status_history
  ADD COLUMN IF NOT EXISTS note TEXT;

UPDATE public.order_status_history
SET note = COALESCE(note, notes)
WHERE note IS NULL;

-- 4) Orders policies for checkout via backend/service-role and user reads
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders"
  ON public.orders FOR INSERT
  WITH CHECK (
    auth.uid() = buyer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
CREATE POLICY "Users can update own orders"
  ON public.orders FOR UPDATE
  USING (
    auth.uid() = buyer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Service role can manage orders" ON public.orders;
CREATE POLICY "Service role can manage orders"
  ON public.orders FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- 5) Order items policies for create/read via backend/service-role
DROP POLICY IF EXISTS "Users can create own order items" ON public.order_items;
CREATE POLICY "Users can create own order items"
  ON public.order_items FOR INSERT
  WITH CHECK (
    auth.uid() = buyer_id
    OR auth.uid() = farmer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items"
  ON public.order_items FOR SELECT
  USING (
    auth.uid() = buyer_id
    OR auth.uid() = farmer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Service role can manage order items" ON public.order_items;
CREATE POLICY "Service role can manage order items"
  ON public.order_items FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- 6) Notifications policies: allow backend to create user notifications
DROP POLICY IF EXISTS "Service role can manage notifications" ON public.notifications;
CREATE POLICY "Service role can manage notifications"
  ON public.notifications FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

COMMIT;

-- Verification checks
SELECT policyname, tablename
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items', 'notifications')
ORDER BY tablename, policyname;

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'payments'
  AND column_name IN ('provider', 'transaction_id', 'method', 'transaction_ref', 'payment_method');
