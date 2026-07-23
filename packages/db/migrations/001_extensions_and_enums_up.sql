-- 001_extensions_and_enums_up.sql
-- 출처: 작성_05_AGIT_DB생성SQL_v0_1.md (문서에서 파일로 분리, 내용 무변경)

create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists vector;      -- pgvector (임베딩 1536d)
create type ws_role           as enum ('운영자', '멤버');
create type member_status     as enum ('invited', 'active', 'removed');
create type team_role         as enum ('CEO', 'COO', 'CFO', 'CPO', 'CTO', 'CMO');
create type class_status      as enum ('draft', 'active', 'closed', 'archived');
create type progress          as enum ('pending', 'in_progress', 'done');
create type piq_level         as enum ('L0', 'L1', 'L2', 'L3', 'L4', 'L5');
create type chat_channel      as enum ('personal', 'team_shared');
create type sender_type       as enum ('user', 'ai');
create type money_kind        as enum ('S', 'R', 'G', 'B');
create type enrollment_status as enum ('invited', 'enrolled', 'unassigned');
create type board_kind        as enum ('notice', 'material', 'qna');
create type ops_kind          as enum ('attendance', 'meeting', 'photo');
