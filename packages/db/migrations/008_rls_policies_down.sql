-- 008_rls_policies_down.sql  v0.1
do $$
declare r record;
begin
  for r in select schemaname, tablename, policyname from pg_policies where schemaname = 'public'
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

alter table users disable row level security;

drop function if exists private.is_ws_member(uuid);
drop function if exists private.is_ws_admin(uuid);
drop function if exists private.is_team_member(uuid);
drop function if exists private.shares_workspace(uuid);
drop schema if exists private cascade;
