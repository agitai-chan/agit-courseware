-- 007_enable_rls_up.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

alter table workspaces        enable row level security;
alter table memberships       enable row level security;
alter table courses           enable row level security;
alter table modules           enable row level security;
alter table tasks             enable row level security;
alter table classes           enable row level security;
alter table teams             enable row level security;
alter table team_members      enable row level security;
alter table class_enrollments enable row level security;
alter table assignments       enable row level security;
alter table submissions       enable row level security;
alter table prompt_events     enable row level security;
alter table piq_scores        enable row level security;
alter table ai_team_projects  enable row level security;
alter table chat_messages     enable row level security;
alter table notes             enable row level security;
alter table files             enable row level security;
alter table peer_feedbacks    enable row level security;
alter table money_game_ledger enable row level security;
alter table board_posts       enable row level security;
alter table ops_records       enable row level security;
-- ⚠️ RLS를 켜면 정책이 없는 동안 모든 접근이 차단됩니다.
--    실제 격리 정책(테넌트 \+ 역할별 \+ 팀 격리 F-027)은 008_rls_policies 에서 정의.
--    정책은 auth.uid()/JWT claim에 의존하므로 C-DB-02(users RLS 예외) 결정 후 작성.
