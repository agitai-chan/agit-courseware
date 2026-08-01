# RUN — AGIT DB 마이그레이션

## 로컬 dry-run (R1, 누구나)
1. PostgreSQL 16 + pgvector(>=0.5) 준비
2. `./dryrun.sh`  → up(001~008) → down → up 재실행 → 격리 시험까지 한 번에
3. 증거: 각 줄의 `[0]` = exit code 0

`sandbox/000_supabase_stub.sql` 은 **샌드박스 전용**이다. Supabase 에서는 실행하지 않는다
(auth 스키마·anon/authenticated 롤이 이미 있다).

## 개발 Supabase 적용 (R3 — 사람만)
1. `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f migrations/001_..._up.sql` 순서대로 001→008
2. `supabase db push` 는 쓰지 않는다 — CLI 는 `supabase/migrations/<timestamp>_<name>.sql`
   패턴만 인식하고 `_down.sql` 도 전진 마이그레이션으로 함께 실행한다 (C-DB-06)
3. service_role 키는 사용하지 않는다. RLS 를 우회하므로 격리 검증이 무의미해진다
