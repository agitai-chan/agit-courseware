# spec.md — AGIT Courseware (입력·처리·출력·완료 기준)

정본(★): 작성_01 사업계획서 > 작성_02 PRD > 작성_03 화면·기능 기획서
이 파일은 저장소의 계약 요약이다. 숫자·기능 목록의 주인은 정본이며, 여기서 재정의하지 않는다.

## 시스템 스펙 3줄
- **입력** — HTTP 요청: `Authorization: Bearer <Supabase JWT>` + `x-workspace-id: <uuid>` + zod 검증 JSON
- **처리** — 인증 → 워크스페이스 멤버십 → 역할 게이트 → 사용자 JWT를 실은 Supabase 클라이언트로 쿼리(RLS 적용)
- **출력** — 타입 추론된 JSON (`AppRouter` 타입이 Web·Mobile로 그대로 전달)

## 완료 기준 (규칙_04 ④ 게이트)
| 게이트 | 판정 방법 |
| --- | --- |
| G1 실행 | `pnpm typecheck` 0에러 + 실제 요청 로그 |
| G2 테스트 | `pnpm test` N/N PASS (신규 기능마다 최소 1개) |
| G3 비밀정보 | `pnpm gate` |
| G4 개인정보 | `python3 gate_check.py . --pii` + **사람 확인** |
| G5 롤백 지점 | `ok-*` 또는 `baseline-*` 태그 |
| G6 의존성 | DECISIONS.md |
| G7 비가역 | `pnpm gate` (packages/db/migrations 의 up↔down 짝) |

## 범위 (v1.0 MVP)
PRD §7 백로그의 P0 33개. API 그룹은 §6.3의 15개를 넘기지 않는다.
현재 구현: **API-02(워크스페이스/멤버) 일부**. 나머지 14그룹은 빈 라우터.
