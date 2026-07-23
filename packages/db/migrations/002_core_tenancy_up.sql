-- 002_core_tenancy_up.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

create table workspaces (
    id           uuid primary key default gen_random_uuid(),
    name         text not null,
    type         text not null,
    logo_url     text,
    subscription jsonb not null default '{}'::jsonb,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);
-- [열림 C-DB-02] users 는 전역 계정 → workspace_id 없음(예외). 격리는 memberships 담당.
create table users (
    id               uuid primary key default gen_random_uuid(),
    email            text unique not null,      -- PII: 개발 시 가상값만
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
