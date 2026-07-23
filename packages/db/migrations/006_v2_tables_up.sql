-- 006_v2_tables_up.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

create table peer_feedbacks (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    task_id      uuid not null references tasks(id) on delete cascade,
    team_id      uuid not null references teams(id) on delete cascade,
    rater_id     uuid references users(id),
    ratee_id     uuid references users(id),
    scores       jsonb not null default '{}'::jsonb,   -- 6x6=36
    created_at   timestamptz not null default now()
);
create index idx_peer_feedbacks_ws on peer_feedbacks (workspace_id);
create table money_game_ledger (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    team_id      uuid not null references teams(id) on delete cascade,
    module_id    uuid references modules(id),
    kind         money_kind not null,                  -- S/R/G/B
    amount       bigint not null,                      -- 가상 게임머니(원)
    balance      bigint not null,
    created_at   timestamptz not null default now()
);
create index idx_money_ledger_ws on money_game_ledger (workspace_id);
create index idx_money_ledger_team on money_game_ledger (team_id);
create table board_posts (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    class_id     uuid not null references classes(id) on delete cascade,
    kind         board_kind not null,                  -- 공지/자료/Q\&A
    author_id    uuid references users(id),
    pinned       boolean not null default false,
    attachments  jsonb not null default '[]'::jsonb,
    body         text,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);
create index idx_board_posts_ws on board_posts (workspace_id);
create table ops_records (
    workspace_id uuid not null references workspaces(id) on delete cascade,
    id           uuid primary key default gen_random_uuid(),
    class_id     uuid not null references classes(id) on delete cascade,
    kind         ops_kind not null,                    -- 출결/회의/사진
    module_id    uuid references modules(id),
    data         jsonb not null default '{}'::jsonb,
    created_at   timestamptz not null default now()
);
create index idx_ops_records_ws on ops_records (workspace_id);
