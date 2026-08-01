-- 002_core_tenancy_up.sql  v0.2
-- E-01 workspaces / E-03 users / E-02 memberships
-- v0.1 대비 변경: [C-DB-05] users.id 를 auth.users.id 에 종속시킨다 (잠정 채택·AI 제안, 사람 승인 필요).
--   근거: 작성_06 tRPC context 가 userId = supabase.auth.getUser() 를 쓴다.
--         두 id 가 다르면 memberships 조회가 항상 0행 → 모든 workspaceProcedure 가 FORBIDDEN.
--   버린 대안: users 를 독립 PK 로 두고 sso_subject 로 조인 → 조인 1회 추가 + RLS 정책이 복잡해짐.
--   재검토 트리거: Supabase Auth 가 아닌 자체 SSO 로 전환할 때.

create table workspaces (
    id           uuid primary key default gen_random_uuid(),
    name         text not null,
    type         text not null,
    logo_url     text,
    subscription jsonb not null default '{}'::jsonb,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

-- [C-DB-02 잠정 종결] users 는 전역 계정 → workspace_id 없음(예외). 격리는 memberships + RLS(008).
-- [C-DB-05] default gen_random_uuid() 제거. id 는 auth.users 가 정한다.
create table users (
    id               uuid primary key references auth.users(id) on delete cascade,
    email            text unique not null,      -- PII: 개발 시 가상값만 (G4)
    sso_subject      text unique,
    profile          jsonb not null default '{}'::jsonb,
    minor_consent_at timestamptz,               -- F-003 미성년 동의
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

create table memberships (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    user_id      uuid not null references users(id) on delete cascade,
    role         ws_role not null,
    status       member_status not null default 'active',
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now(),
    primary key (workspace_id, user_id)
);

create index idx_memberships_user on memberships (user_id);

-- 부트스트랩 (1) 계정 생성 시 public.users 행을 만든다.
--   security definer: 트리거 실행 시점에는 RLS 를 우회해야 한다.
--   대안(권한 문제로 auth 스키마에 트리거를 못 걸 때): API 레이어에서 로그인 직후 upsert.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
    insert into public.users (id, email, sso_subject, profile)
    values (new.id,
            coalesce(new.email, new.id::text || '@placeholder.invalid'),
            new.raw_user_meta_data ->> 'sub',
            coalesce(new.raw_user_meta_data, '{}'::jsonb))
    on conflict (id) do nothing;
    return new;
end $$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- 부트스트랩 (2) F-005 수용조건 "생성자 자동 운영자" [검증됨]
create or replace function public.handle_new_workspace() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
    if auth.uid() is not null then
        insert into public.memberships (workspace_id, user_id, role, status)
        values (new.id, auth.uid(), '운영자', 'active')
        on conflict do nothing;
    end if;
    return new;
end $$;

create trigger on_workspace_created
    after insert on workspaces
    for each row execute function public.handle_new_workspace();
