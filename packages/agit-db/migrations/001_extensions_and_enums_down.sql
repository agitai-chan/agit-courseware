drop type if exists ops_kind, board_kind, enrollment_status, money_kind,

    sender_type, chat_channel, piq_level, progress, class_status,

    team_role, member_status, ws_role;

-- 확장(vector·pgcrypto)은 다른 스키마와 공유될 수 있어 down에서 drop하지 않는다.
