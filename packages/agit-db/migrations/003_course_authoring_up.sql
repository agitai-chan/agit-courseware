create table courses (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    title        text not null,

    intro        text,

    owner_id     uuid references users(id),

    type         text,

    archived     boolean not null default false,

    created_at   timestamptz not null default now(),

    updated_at   timestamptz not null default now()

);

create index idx_courses_ws on courses (workspace_id);

create table modules (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    course_id    uuid not null references courses(id) on delete cascade,

    title        text not null,

    goal         text,

    hours        numeric,

    sort_order   integer not null default 0,

    created_at   timestamptz not null default now(),

    updated_at   timestamptz not null default now()

);

create index idx_modules_ws on modules (workspace_id);

create index idx_modules_course on modules (course_id);

create table tasks (

    workspace_id uuid not null references workspaces(id) on delete cascade,

    id           uuid primary key default gen_random_uuid(),

    module_id    uuid not null references modules(id) on delete cascade,

    title        text not null,

    goal         text,

    instruction  text,

    deliverable  text,

    eval_tags    jsonb not null default '{}'::jsonb,

    created_at   timestamptz not null default now(),

    updated_at   timestamptz not null default now()

);

create index idx_tasks_ws on tasks (workspace_id);

create index idx_tasks_module on tasks (module_id);
