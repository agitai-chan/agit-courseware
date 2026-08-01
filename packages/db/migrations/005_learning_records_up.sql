create table submissions (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    task_id      uuid not null references tasks(id) on delete cascade,

    team_id      uuid not null references teams(id) on delete cascade,

    member_id    uuid references users(id),

    content      jsonb not null default '{}'::jsonb,

    submitted_at timestamptz not null default now(),

    is_evidence  boolean not null default false   -- 발표 산출물 여부

);

create index idx_submissions_ws on submissions (workspace_id);

create index idx_submissions_task on submissions (task_id);

create table prompt_events (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    member_id    uuid not null references users(id),   -- 개인 축

    team_id      uuid references teams(id),            -- 팀 축

    task_id      uuid references tasks(id),            -- Task 축

    prompt       text not null,

    channel      chat_channel not null,

    ts           timestamptz not null default now(),   -- Time 축

    embedding    vector(1536)                          -- TPCG/RAG

);

create index idx_prompt_events_ws on prompt_events (workspace_id);

create index idx_prompt_events_member_ts on prompt_events (member_id, ts);

-- pgvector >= 0.5 필요:

create index idx_prompt_events_embedding

    on prompt_events using hnsw (embedding vector_cosine_ops);

create table piq_scores (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    member_id    uuid not null references users(id),

    task_id      uuid references tasks(id),

    level        piq_level not null,                   -- L0~L5

    dimensions   jsonb not null default '{}'::jsonb,   -- 6차원 0.0~1.0

    z_score      numeric,

    ts           timestamptz not null default now()

);

create index idx_piq_scores_ws on piq_scores (workspace_id);

create index idx_piq_scores_member_ts on piq_scores (member_id, ts);

create table ai_team_projects (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    team_id      uuid not null unique references teams(id) on delete cascade,

    context      jsonb not null default '{}'::jsonb,   -- 자체 추상화 레이어

    embedding    vector(1536),                         -- pgvector RAG

    created_at   timestamptz not null default now(),

    updated_at   timestamptz not null default now()

);

create index idx_ai_team_projects_ws on ai_team_projects (workspace_id);

create table chat_messages (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    channel      chat_channel not null,

    sender       sender_type not null,

    sender_id    uuid references users(id),   -- AI면 null

    task_id      uuid references tasks(id),

    team_id      uuid references teams(id),

    body         text not null,

    ts           timestamptz not null default now()

);

create index idx_chat_messages_ws on chat_messages (workspace_id);

create index idx_chat_messages_task on chat_messages (task_id);

create table notes (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    user_id      uuid not null references users(id) on delete cascade,

    content      text,

    tags         text[] not null default '{}',

    created_at   timestamptz not null default now(),

    updated_at   timestamptz not null default now()

);

create index idx_notes_ws on notes (workspace_id);

create table files (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    user_id      uuid not null references users(id) on delete cascade,

    file_meta    jsonb not null default '{}'::jsonb,

    path         text not null,

    created_at   timestamptz not null default now()

);

create index idx_files_ws on files (workspace_id);
