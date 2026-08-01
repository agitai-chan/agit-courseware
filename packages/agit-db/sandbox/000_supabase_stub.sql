-- ⚠️ 샌드박스 전용 스텁 — 마이그레이션이 아니다. Supabase에는 이미 존재하는 것들이다.
--    migrations/ 밖에 두는 이유: G7 검사 대상에 섞이면 안 된다.
create extension if not exists pgcrypto;

create schema if not exists auth;

create table if not exists auth.users (
    id                  uuid primary key default gen_random_uuid(),
    email               text unique,
    raw_user_meta_data  jsonb not null default '{}'::jsonb,
    created_at          timestamptz not null default now()
);

-- Supabase의 auth.uid() 대용: JWT sub 클레임을 GUC로 흉내낸다.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
end $$;

grant usage on schema auth to anon, authenticated;
