# DECISIONS.md — 되돌리기 어려운 선택 (→ 규칙_03_History ② 로 승격)

## 2026-07-22 저장소 구조 = 최소 모노레포 (pnpm workspace)
- **근거:** 정본 C-001(Web Next.js / Mobile Expo 분리)에서 두 앱이 같은 `AppRouter` 타입을 봐야 tRPC 선택이 성립한다.
- **버린 대안:** 단일 Next.js 레포(모바일 타입 공유 불가), Edge Functions 단독 레포(C-API-02를 조기 고정).
- **재검토 트리거:** 모바일을 v2.0으로 연기하기로 하면 단일 레포로 축소.

## 2026-07-22 어댑터는 fetch 표준 (`createFetchHandler`)
- **근거:** C-API-02(Vercel Route Handler vs Supabase Edge Function) 미확정. fetch 어댑터는 양쪽 모두에서 동작.
- **재검토 트리거:** C-API-02 확정 시 한쪽으로 단순화.

## G6 의존성 (2026-07-22 npm 레지스트리 실조회)
| 패키지 | 고정 버전 | 라이선스 | 사유 |
| --- | --- | --- | --- |
| @trpc/server | 11.18.0 | MIT | 정본 §6.3이 지정한 타입 안전 API 게이트웨이 |
| zod | 4.4.3 | MIT | 입력 검증 = F-047 인젝션 방어 1차선 |
| superjson | 2.2.6 | MIT | Date 등 직렬화(PromptEvent 시계열 보존) |
| @supabase/supabase-js | 2.110.8 | MIT | Auth·RLS 적용 쿼리 |
| next | **14.2.35** | MIT | **정본 §6.3이 "Next.js 14" 명시.** 최신은 16.2.11 — 정본 갱신 전까지 14 고정 |
| react / react-dom | 18.3.1 | MIT | Next 14 기본 조합 |
| tsx | 4.23.1 | MIT | TS 테스트 실행(esbuild 기반) |
| typescript | 5.9.3 | Apache-2.0 | 최신은 7.0.2(네이티브 포트) — 안정성 위해 5.x 고정 |

*zod 4.x + tRPC 11 조합은 타입체크·스텁 테스트까지만 확인. 실제 입력 검증 런타임은 미검증 [추정].*
