# AGIT Courseware

모의창업 코스웨어. 정본(★)은 `작성_01 사업계획서` > `작성_02 PRD` > `작성_03 화면·기능 기획서`.

```
packages/api   tRPC 라우터 (계약의 주인) — Web·Mobile이 같은 타입을 본다
packages/db    마이그레이션 SQL (up↔down 7쌍). 실행은 R3 = 사람
apps/web       Next.js 14. api/trpc 라우트는 3줄 어댑터
apps/mobile    Expo (v1.0 후반)
```

실행·검증은 **RUN.md**, 계약은 **spec.md**, 되돌리기 어려운 선택은 **DECISIONS.md**.

## 규칙 (규칙_04 Expert_VibeCoding)
- 한 기능 = 한 실행 확인 = 한 커밋
- 증거 없는 완료는 완료가 아니다 (`pnpm test` 출력을 붙인다)
- service_role 키·실제 개인정보는 이 저장소에 들어오지 않는다
