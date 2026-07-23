-- 001_extensions_and_enums_down.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

drop type if exists ops_kind, board_kind, enrollment_status, money_kind,
    sender_type, chat_channel, piq_level, progress, class_status,
    team_role, member_status, ws_role;
-- 확장(vector·pgcrypto)은 다른 스키마와 공유될 수 있어 down에서 drop하지 않는다.
