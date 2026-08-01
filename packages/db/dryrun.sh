#!/usr/bin/env bash
# dryrun.sh — 로컬 Postgres 16 에서 up → down → up 왕복 + 격리 시험
# 사용: ./dryrun.sh   (증거 로그를 stdout 으로 남긴다)
set -u
DB=${1:-agit_dryrun}
export PGHOST=${PGHOST:-/tmp}
UP=$(ls migrations/*_up.sql | sort)
DOWN=$(ls migrations/*_down.sql | sort -r)

run() { psql -d "$DB" -v ON_ERROR_STOP=1 -q -f "$1" >/tmp/o 2>&1; local rc=$?; \
        printf '[%s] %s\n' "$rc" "$1"; [ $rc -ne 0 ] && sed -n 1,6p /tmp/o; return $rc; }

dropdb --if-exists "$DB" >/dev/null 2>&1; createdb "$DB" || exit 1
echo "── 0) Supabase 스텁(샌드박스 전용)"; run sandbox/000_supabase_stub.sql || exit 1
echo "── 1) UP  (001→008)"; for f in $UP;   do run "$f" || exit 1; done
psql -d "$DB" -tAc "select 'tables='||count(*) from pg_tables where schemaname='public'" 
psql -d "$DB" -tAc "select 'policies='||count(*) from pg_policies where schemaname='public'"
psql -d "$DB" -tAc "select 'rls_off='||coalesce(string_agg(tablename,','),'(없음)') from pg_tables where schemaname='public' and not rowsecurity"
echo "── 2) DOWN (008→001)"; for f in $DOWN; do run "$f" || exit 1; done
psql -d "$DB" -tAc "select 'tables_left='||count(*) from pg_tables where schemaname='public'"
psql -d "$DB" -tAc "select 'enums_left='||count(*) from pg_type where typtype='e'"
echo "── 3) UP 재실행 (멱등·재현성)"; for f in $UP; do run "$f" || exit 1; done
echo "── 4) 격리 시험"; psql -d "$DB" -f sandbox/isolation_test.sql 2>&1
echo "── 5) 적용 검증 8항목"; psql -d "$DB" -f verify/verify_supabase.sql 2>&1
