-- 007_enable_rls_down.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

alter table ops_records       disable row level security;
alter table board_posts       disable row level security;
alter table money_game_ledger disable row level security;
alter table peer_feedbacks    disable row level security;
alter table files             disable row level security;
alter table notes             disable row level security;
alter table chat_messages     disable row level security;
alter table ai_team_projects  disable row level security;
alter table piq_scores        disable row level security;
alter table prompt_events     disable row level security;
alter table submissions       disable row level security;
alter table assignments       disable row level security;
alter table class_enrollments disable row level security;
alter table team_members      disable row level security;
alter table teams             disable row level security;
alter table classes           disable row level security;
alter table tasks             disable row level security;
alter table modules           disable row level security;
alter table courses           disable row level security;
alter table memberships       disable row level security;
alter table workspaces        disable row level security;
