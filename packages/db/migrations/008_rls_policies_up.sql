-- 008_rls_policies_up.sql  v0.1
-- 범위: 테넌트 격리 + 소유자/팀 격리 (F-007 · F-027)
-- 범위 밖: 교사/학생 역할별 분기 → [열림 C-API-01] 확정 후 009 에서. 지어내지 않는다.
--          지금은 "운영자 = 쓰기 / 멤버 = 읽기" 2단계만 강제한다.
-- 주의: 정책이 memberships 를 직접 조회하면 memberships 자신의 정책이 재귀한다.
--       → 헬퍼 함수를 security definer 로 만들어 RLS 를 우회시킨다(표준 회피법).

create schema if not exists private;
revoke all on schema private from public;

create or replace function private.is_ws_member(ws uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
    select exists (select 1 from memberships m
                   where m.workspace_id = ws and m.user_id = auth.uid() and m.status = 'active');
$$;

create or replace function private.is_ws_admin(ws uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
    select exists (select 1 from memberships m
                   where m.workspace_id = ws and m.user_id = auth.uid()
                     and m.status = 'active' and m.role = '운영자');
$$;

create or replace function private.is_team_member(t uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
    select exists (select 1 from team_members tm
                   where tm.team_id = t and tm.user_id = auth.uid());
$$;

create or replace function private.shares_workspace(target uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
    select exists (select 1 from memberships a join memberships b using (workspace_id)
                   where a.user_id = auth.uid() and b.user_id = target
                     and a.status = 'active' and b.status = 'active');
$$;

grant usage on schema private to authenticated;
grant execute on all functions in schema private to authenticated;

-- 007 이 빠뜨린 테이블. users 는 email(PII)을 담는다 → RLS 없이 두면 anon 키로 전량 조회된다.
alter table users enable row level security;

-- 접근 표면: 로그인한 사용자만. anon 은 테이블에 손대지 못한다.
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
revoke all on all tables in schema public from anon;

-- ── E-03 users ────────────────────────────────────────────────
create policy users_select on users for select to authenticated
    using (id = auth.uid() or private.shares_workspace(id));
create policy users_update_self on users for update to authenticated
    using (id = auth.uid()) with check (id = auth.uid());
-- insert/delete 정책 없음: 계정 생성은 002 의 security definer 트리거만 한다.

-- ── E-01 workspaces ───────────────────────────────────────────
create policy ws_select on workspaces for select to authenticated
    using (private.is_ws_member(id));
create policy ws_insert on workspaces for insert to authenticated
    with check (auth.uid() is not null);              -- F-005, 생성자는 트리거가 운영자로 등록
create policy ws_update on workspaces for update to authenticated
    using (private.is_ws_admin(id)) with check (private.is_ws_admin(id));
create policy ws_delete on workspaces for delete to authenticated
    using (private.is_ws_admin(id));

-- ── E-02 memberships ──────────────────────────────────────────
create policy mb_select on memberships for select to authenticated
    using (private.is_ws_member(workspace_id));
create policy mb_write on memberships for all to authenticated
    using (private.is_ws_admin(workspace_id)) with check (private.is_ws_admin(workspace_id));

-- ── 저작·운영 테이블: 읽기=멤버 / 쓰기=운영자 ────────────────
do $$
declare t text;
begin
  foreach t in array array['courses','modules','tasks','classes','teams','team_members',
                           'class_enrollments','assignments','board_posts','ops_records']
  loop
    execute format('create policy %I_select on %I for select to authenticated
                      using (private.is_ws_member(workspace_id))', t, t);
    execute format('create policy %I_write on %I for all to authenticated
                      using (private.is_ws_admin(workspace_id))
                      with check (private.is_ws_admin(workspace_id))', t, t);
  end loop;
end $$;

-- ── E-11 submissions : 팀 격리 (F-027) ────────────────────────
create policy sub_select on submissions for select to authenticated
    using (private.is_ws_member(workspace_id)
           and (private.is_team_member(team_id) or private.is_ws_admin(workspace_id)));
create policy sub_insert on submissions for insert to authenticated
    with check (private.is_team_member(team_id) and member_id = auth.uid());
create policy sub_update on submissions for update to authenticated
    using (member_id = auth.uid()) with check (member_id = auth.uid());

-- ── E-12 prompt_events : 개인 축 ──────────────────────────────
create policy pe_select on prompt_events for select to authenticated
    using (member_id = auth.uid() or private.is_ws_admin(workspace_id));
create policy pe_insert on prompt_events for insert to authenticated
    with check (member_id = auth.uid() and private.is_ws_member(workspace_id));

-- ── E-13 piq_scores : 읽기만. 점수는 서버가 쓴다 ──────────────
create policy piq_select on piq_scores for select to authenticated
    using (member_id = auth.uid() or private.is_ws_admin(workspace_id));

-- ── E-21 ai_team_projects : 팀 공유 컨텍스트 ──────────────────
create policy aitp_select on ai_team_projects for select to authenticated
    using (private.is_team_member(team_id) or private.is_ws_admin(workspace_id));
create policy aitp_write on ai_team_projects for all to authenticated
    using (private.is_team_member(team_id)) with check (private.is_team_member(team_id));

-- ── E-18 chat_messages : personal=본인 / team_shared=팀 ───────
create policy cm_select on chat_messages for select to authenticated
    using (case when channel = 'personal' then sender_id = auth.uid()
                else private.is_team_member(team_id) end);
create policy cm_insert on chat_messages for insert to authenticated
    with check (private.is_ws_member(workspace_id)
                and (sender_id = auth.uid() or sender = 'ai'));

-- ── E-16/17 notes · files : 개인 전용 ─────────────────────────
create policy notes_own on notes for all to authenticated
    using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy files_own on files for all to authenticated
    using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── v2.0 테이블 : 최소 정책 (v2.0 착수 때 재설계) ─────────────
create policy pf_select on peer_feedbacks for select to authenticated
    using (rater_id = auth.uid() or private.is_ws_admin(workspace_id));
create policy pf_insert on peer_feedbacks for insert to authenticated
    with check (rater_id = auth.uid() and private.is_ws_member(workspace_id));
create policy mgl_select on money_game_ledger for select to authenticated
    using (private.is_team_member(team_id) or private.is_ws_admin(workspace_id));
create policy mgl_write on money_game_ledger for all to authenticated
    using (private.is_ws_admin(workspace_id)) with check (private.is_ws_admin(workspace_id));
