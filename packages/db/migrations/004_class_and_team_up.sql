-- 004_class_and_team_up.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

create table classes (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    course_id    uuid not null references courses(id),   -- 스냅샷 원본 참조(F-015)
    teacher_id   uuid references users(id),
    period       tstzrange,
    location     text,
    status       class_status not null default 'draft',
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);
create index idx_classes_ws on classes (workspace_id);
create table teams (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    class_id     uuid not null references classes(id) on delete cascade,
    name         text not null,
    icon         text,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);
create index idx_teams_ws on teams (workspace_id);
create index idx_teams_class on teams (class_id);
create table team_members (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    team_id      uuid not null references teams(id) on delete cascade,
    user_id      uuid not null references users(id) on delete cascade,
    role         team_role not null,          -- CEO/COO/CFO/CPO/CTO/CMO
    created_at   timestamptz not null default now(),
    primary key (team_id, user_id)
);
create index idx_team_members_ws on team_members (workspace_id);
-- [추정·추가 C-DB-01] 정본 E-목록에 없음. F-021(수강생 관리·"미배정 식별")이 요구.
create table class_enrollments (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    class_id     uuid not null references classes(id) on delete cascade,
    user_id      uuid not null references users(id) on delete cascade,
    status       enrollment_status not null default 'invited',
    created_at   timestamptz not null default now(),
    unique (class_id, user_id)
);
create index idx_enrollments_ws on class_enrollments (workspace_id);
create table assignments (
    workspace_id    uuid not null references workspaces(id) on delete cascade,
    id              uuid primary key default gen_random_uuid(),
    class_id        uuid not null references classes(id) on delete cascade,
    team_id         uuid not null references teams(id) on delete cascade,
    module_id       uuid references modules(id),
    task_id         uuid references tasks(id),      -- 부분 할당(F-022)
    progress_status progress not null default 'pending',
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);
create index idx_assignments_ws on assignments (workspace_id);
create index idx_assignments_team on assignments (team_id);
