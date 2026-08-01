-- verify_supabase.sql — 적용 직후 8항목 자동 판정 (읽기 전용, R0)
-- 사용: psql "$SUPABASE_DB_URL" -f verify/verify_supabase.sql
\pset border 2
with c as (
  select '1. 테이블 수'                as 검사, '22'::text as 기대,
         (select count(*)::text from pg_tables where schemaname='public') as 실제
  union all select '2. RLS 정책 수', '44',
         (select count(*)::text from pg_policies where schemaname='public')
  union all select '3. RLS 꺼진 테이블', '0',
         (select count(*)::text from pg_tables where schemaname='public' and not rowsecurity)
  union all select '4. pgvector >= 0.5', 'true',
         (select (string_to_array(extversion,'.')::int[] >= array[0,5])::text
            from pg_extension where extname='vector')
  union all select '5. users.id → auth.users FK', '1',
         (select count(*)::text from pg_constraint
           where conname like '%users%' and contype='f'
             and conrelid='public.users'::regclass
             and confrelid='auth.users'::regclass)
  union all select '6. 부트스트랩 트리거', '2',
         (select count(*)::text from pg_trigger
           where tgname in ('on_auth_user_created','on_workspace_created') and not tgisinternal)
  union all select '7. private 헬퍼 함수', '4',
         (select count(*)::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='private')
  union all select '8. anon 의 public 테이블 권한', '0',
         (select count(*)::text from information_schema.role_table_grants
           where grantee='anon' and table_schema='public')
)
select 검사, 기대, 실제, case when 기대=실제 then 'PASS' else '*** FAIL ***' end as 판정 from c;
