# [작성] AGIT 코스웨어 — DB 적용 절차 v0.2 (R1)

> **2026-07-23 · DECISIONS.md 5건 사람(팀) 승인 완료.** C-DB-01·02·05·06 및 008 범위 제한이 확정됐다.

전문: 바이브코딩 · 근거: 작성_04 스키마설계 / 작성_05 생성SQL / 정본 PRD §6.2·§8
산출물 위치: `agit-db/` (SQL 은 문서가 아니라 파일로 둔다 — 03_History ⑤ 규칙 후보)

## 0. 무엇이 바뀌었나 (작성_05 v0.1 대비)

| 파일 | 변경 | 이유 |
|:--|:--|:--|
| `002_core_tenancy_up/down.sql` | **v0.2** — `users.id` → `auth.users(id)` FK, `handle_new_user`·`handle_new_workspace` 트리거 추가 | C-DB-05 (미수정 시 로그인 후 전 API FORBIDDEN) |
| `008_rls_policies_up/down.sql` | **신규** — 헬퍼 4개 + 정책 44개 | C-DB-02 종결 · F-007 · F-027 |
| `sandbox/`, `dryrun.sh`, `RUN.md`, `DECISIONS.md` | 신규 | 실행 검증 하네스 |
| 001·003~007 | **무변경** | 실행 검증 통과 |

## 1. 사람이 할 일 (순서대로)

### 1단계 · 결정 승인 — **완료 (2026-07-23)**
DECISIONS.md 5건 승인됨. 되돌리려면 각 항목의 '재검토 트리거' 참조.

### 2단계 · 개발용 Supabase 프로젝트 생성 (R3)
- 운영과 분리된 **개발 전용** 프로젝트. 리전은 서울(ap-northeast-2) 권장
- `.env.local` 에 `SUPABASE_URL` · `SUPABASE_ANON_KEY` 저장
- **`service_role` 키는 저장소·AI 대화 어디에도 넣지 않는다** (RLS 우회 → 격리 검증이 무의미)
- 확인: `select extversion from pg_extension where extname='vector';` → **0.5 이상**

### 3단계 · 적용 (R3 — 사람이 실행)
```
export SUPABASE_DB_URL='postgresql://...'      # 대시보드 > Settings > Database
for f in migrations/00{1,2,3,4,5,6,7,8}_*_up.sql; do
  psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$f" || break
done
```
- `sandbox/000_supabase_stub.sql` 은 **실행하지 않는다** (Supabase 에 이미 있다)
- `supabase db push` 를 쓰지 않는다 → C-DB-06
- **007 과 008 은 반드시 같이** 적용한다. 007만 적용하면 정책 0개로 전면 차단된다

### 4단계 · 적용 확인 (증거 수집)
```
psql "$SUPABASE_DB_URL" -c "select count(*) from pg_tables where schemaname='public'"      -- 기대 22
psql "$SUPABASE_DB_URL" -c "select count(*) from pg_policies where schemaname='public'"    -- 기대 44
psql "$SUPABASE_DB_URL" -c "select tablename from pg_tables where schemaname='public' and not rowsecurity"  -- 기대 0행
```

### 5단계 · 실제 계정으로 격리 재확인
샌드박스 스텁은 `auth.uid()` 를 흉내낸 것이다. **Supabase 에서 한 번 더** 확인한다:
Google 계정 2개로 로그인 → 각자 워크스페이스 생성 → 상대 워크스페이스 데이터가 0행인지.

### 5-1단계 · 자동 검증 8항목
```
psql "$SUPABASE_DB_URL" -f verify/verify_supabase.sql
```
8줄 전부 `PASS` 여야 한다. 이 출력이 곧 적용 완료의 증거다.

### 5-2단계 · 가상 시드 (선택)
Auth 로 계정 7개(교사 1 + 학생 6)를 먼저 만든 뒤:
```
psql "$SUPABASE_DB_URL" -v t=<교사uuid> -v s1=.. -v s6=.. -f seed/seed_virtual.sql
```
**auth.users 에 SQL 로 직접 insert 하지 않는다** — 비밀번호 해시·identity 행이 빠져 로그인이 안 된다.
시드는 전부 `*@example.invalid` 가상값이다 (G4).

### 6단계 · 기록
02_Session 에 RUN-0002, 03_History ①②③ 갱신. 이 대화 끝에 "기록해줘" 라고 하면 갱신본 전문을 만든다.

## 1-1. 승인에 따른 연쇄 점검 (P-6-1 — 정본을 고치면 인용한 파일도 추적)

| 파일 | 손봐야 하는 것 | 급한가 |
|:--|:--|:--|
| 작성_04 §2 E-03 `users` | id 설명 `[추정]`→ `auth.users(id) FK` (C-DB-05 승인분) | 다음 개정 |
| 작성_04 §4 이슈표 | C-DB-01·02 를 '확인중'→'확정' 으로 | 다음 개정 |
| 작성_05 002 SQL | v0.2 로 교체. **문서 대신 `migrations/` 파일이 원본**이 된다 | 즉시 |
| 작성_05 검증표 | `111 statements` → **131** 로 정정 (독립 재추출 2회 재현) | 즉시 |
| 작성_06 tRPC context | **변경 없음** — C-DB-05 승인으로 오히려 정합됨 | — |
| ~~정본 PRD §6.2~~ | **완료 — PRD v1.1 로 개정 (E-03·workspace_id 예외·E-22 신설)** | ✅ 2026-07-23 |

정본 반영 완료(v1.1). 이제 다음 세션의 AI 가 같은 [열림]을 다시 열지 않는다.
**02_Session 의 정본 목록도 `PRD v1_1★` 로 갱신해야 한다** — 지식창고에는 현행본만 올린다(P-6-1 파일 4규칙).

## 2. 아직 닫히지 않은 것

| ID | 상태 |
|:--|:--|
| C-DB-03 | AI 팀원 표현 — 스키마 영향 없음, 팀 AI 구현 때 |
| **C-DB-04** | **닫힘 후보**: 131 이 맞다. 독립 재추출로 2회 재현. 작성_05 의 "111" 은 정정 필요 |
| **C-API-01** | 미해결. 008 은 운영자/멤버 2단계까지만. 교사/학생은 009 |
| C-API-02 | 미해결 (DB 작업에는 영향 없음) |
| C-SCHED-01 | 미해결 |

ⓒ 2026 주식회사 애짓 · v0.2 (R1)
