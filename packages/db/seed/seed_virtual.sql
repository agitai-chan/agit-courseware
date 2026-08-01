-- seed_virtual.sql — 가상 데이터 (G4: 실제 PII 금지, 미성년 보호)
-- 마이그레이션이 아니다 → migrations/ 밖에 둔다(G7 대상 아님).
-- 선행: Supabase Auth 로 계정 6개를 먼저 만들고 그 uuid 를 넣는다.
--       (auth.users 에 SQL 로 직접 insert 하지 않는다 — 비밀번호 해시·identity 행이 빠진다)
-- 사용: psql "$SUPABASE_DB_URL" -v t=<교사uuid> -v s1=<uuid> ... -v s6=<uuid> -f seed/seed_virtual.sql
\set ON_ERROR_STOP on
begin;

insert into workspaces (id, name, type) values
  ('a9170000-0000-4000-8000-000000000001', '가상 고등학교', '학교')
on conflict do nothing;

insert into memberships (workspace_id, user_id, role) values
  ('a9170000-0000-4000-8000-000000000001', :'t',  '운영자'),
  ('a9170000-0000-4000-8000-000000000001', :'s1', '멤버'),
  ('a9170000-0000-4000-8000-000000000001', :'s2', '멤버'),
  ('a9170000-0000-4000-8000-000000000001', :'s3', '멤버'),
  ('a9170000-0000-4000-8000-000000000001', :'s4', '멤버'),
  ('a9170000-0000-4000-8000-000000000001', :'s5', '멤버'),
  ('a9170000-0000-4000-8000-000000000001', :'s6', '멤버')
on conflict do nothing;

insert into courses (workspace_id, id, title, intro, owner_id, type) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000010',
   '모의창업 기초','가상 시드 코스', :'t', 'Startup') on conflict do nothing;

insert into modules (workspace_id, id, course_id, title, goal, hours, sort_order) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000020',
   'a9170000-0000-4000-8000-000000000010','1회차 · 문제 정의','고객 문제를 한 줄로', 2, 1)
on conflict do nothing;

insert into tasks (workspace_id, id, module_id, title, goal, instruction, deliverable) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000030',
   'a9170000-0000-4000-8000-000000000020','고객 인터뷰 설계','질문 5개','가상 지시문','질문지 1장')
on conflict do nothing;

insert into classes (workspace_id, id, course_id, teacher_id, location, status) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000040',
   'a9170000-0000-4000-8000-000000000010', :'t', '가상관 301호', 'active') on conflict do nothing;

insert into teams (workspace_id, id, class_id, name, icon) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050',
   'a9170000-0000-4000-8000-000000000040','가상팀 A','🚀') on conflict do nothing;

insert into team_members (workspace_id, team_id, user_id, role) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050', :'s1','CEO'),
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050', :'s2','COO'),
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050', :'s3','CFO'),
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050', :'s4','CPO'),
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050', :'s5','CTO'),
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000050', :'s6','CMO')
on conflict do nothing;

insert into class_enrollments (workspace_id, class_id, user_id, status) values
  ('a9170000-0000-4000-8000-000000000001','a9170000-0000-4000-8000-000000000040', :'s1','enrolled')
on conflict do nothing;

commit;
select '시드 완료 — 워크스페이스 1 · 팀 1 · 팀원 6' as 결과;
