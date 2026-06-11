-- Merge lifestyle_bloggers into brightdata_profiles, then retire the lifestyle table.
-- Policy: INSERT rows that don't already exist (by handle+platform). Rows that DO exist
-- in brightdata_profiles are left untouched — no coalesce/overwrite. The lifestyle data
-- is now redundant once merged, so the table is renamed to *_retired for safety.
--
-- Run ONCE in the Supabase SQL editor.
-- Idempotent: after the rename, to_regclass() returns NULL so re-running is a no-op.
-- Take a Supabase snapshot before running.

do $$
declare cols text; lcols text;
begin
  if to_regclass('public.lifestyle_bloggers') is not null then
    -- Build column list: columns common to both tables, excluding the identity `id`.
    select string_agg(quote_ident(c.column_name), ', ' order by c.ordinal_position),
           string_agg('l.' || quote_ident(c.column_name), ', ' order by c.ordinal_position)
      into cols, lcols
      from information_schema.columns c
     where c.table_schema = 'public' and c.table_name = 'brightdata_profiles'
       and c.column_name <> 'id'
       and exists (
         select 1 from information_schema.columns x
          where x.table_schema = 'public' and x.table_name = 'lifestyle_bloggers'
            and x.column_name = c.column_name
       );

    -- Insert lifestyle-only rows (skip duplicates).
    execute format(
      'insert into brightdata_profiles (%1$s)
         select %2$s from lifestyle_bloggers l
         where not exists (
           select 1 from brightdata_profiles m
            where m.handle = l.handle and m.platform = l.platform
         )', cols, lcols);

    -- Retire lifestyle_bloggers (reversible — drop manually after verifying).
    if to_regclass('public.lifestyle_bloggers_retired') is null then
      alter table lifestyle_bloggers rename to lifestyle_bloggers_retired;
    end if;

    raise notice 'lifestyle_bloggers merged into brightdata_profiles and renamed to lifestyle_bloggers_retired.';
  else
    raise notice 'lifestyle_bloggers not found — already merged or renamed. No-op.';
  end if;
end $$;
