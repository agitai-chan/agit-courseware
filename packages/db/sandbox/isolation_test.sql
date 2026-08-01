\set ON_ERROR_STOP off
-- 격리 시험 (F-007 테넌트 격리 · F-027 팀 격리)
-- 데이터는 전부 가상값이다 (G4).
\echo '=== SETUP (superuser) ==='
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111','u1@example.invalid'),
  ('22222222-2222-2222-2222-222222222222','u2@example.invalid'),
  ('33333333-3333-3333-3333-333333333333','u3@example.invalid');
select count(*) as "public.users 자동생성" from users;

\echo ''
\echo '=== T1. u1 이 워크스페이스 생성 → 자동 운영자? (F-005) ==='
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111', true);
  insert into workspaces (id, name, type) values ('aaaaaaaa-0000-0000-0000-000000000001','AGIT 1반','학교');
  select role as "T1 결과(기대: 운영자)" from memberships where workspace_id='aaaaaaaa-0000-0000-0000-000000000001';
commit;

begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  insert into workspaces (id, name, type) values ('bbbbbbbb-0000-0000-0000-000000000002','다른학교','학교');
commit;

\echo ''
\echo '=== T2. u1 에게 보이는 워크스페이스 수 (기대: 1) ==='
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111', true);
  select count(*) as "T2 (기대 1)" from workspaces;
  insert into memberships (workspace_id,user_id,role) values ('aaaaaaaa-0000-0000-0000-000000000001','33333333-3333-3333-3333-333333333333','멤버');
  insert into courses (workspace_id,id,title,owner_id) values ('aaaaaaaa-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001','모의창업 코스','11111111-1111-1111-1111-111111111111');
  select count(*) as "T3 u1 에게 보이는 users (기대 2)" from users;
commit;

\echo ''
\echo '=== T4. u2 에게 보이는 타 테넌트 코스 (기대: 0 — F-007 수용조건) ==='
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  select count(*) as "T4 (기대 0)" from courses;
  select count(*) as "T5 u2 에게 보이는 users (기대 1=본인)" from users;
commit;

\echo ''
\echo '=== T6. 멤버(u3)가 코스 생성 시도 → 기대: 거부 ==='
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333', true);
  insert into courses (workspace_id,title) values ('aaaaaaaa-0000-0000-0000-000000000001','몰래 만든 코스');
rollback;

\echo ''
\echo '=== T7. u3 가 남의 워크스페이스(w2)에 코스 생성 시도 → 기대: 거부 ==='
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333', true);
  insert into courses (workspace_id,title) values ('bbbbbbbb-0000-0000-0000-000000000002','침입 코스');
rollback;

\echo ''
\echo '=== T8. anon 키로 users 조회 → 기대: 거부 (email = PII) ==='
begin;
  set local role anon;
  select count(*) from users;
rollback;

\echo ''
\echo '=== T9. 개인 노트 격리 ==='
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111', true);
  insert into notes (workspace_id,user_id,content) values ('aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','u1 의 메모');
commit;
begin;
  set local role authenticated;
  select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333', true);
  select count(*) as "T9 u3 가 보는 u1 노트 (기대 0)" from notes;
rollback;
