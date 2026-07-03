-- Adjustable display name for outreach + pilot records.
-- Records are keyed by handle, but many creators go by a nickname / real name that
-- differs from their handle. `name` is an editable free-text label shown alongside
-- the handle in both pipelines. Run in the Supabase SQL editor.

ALTER TABLE influencer_outreach
  ADD COLUMN IF NOT EXISTS name text;

ALTER TABLE influencer_pilot_calls
  ADD COLUMN IF NOT EXISTS name text;
