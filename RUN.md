# RUN.md — 클론에서 실행까지

## 0. 요구 환경 (검증된 조합)
- Node **v22.22.2** (테스트 러너 `node --test` 사용)
- pnpm **11.15.1** (`packageManager` 필드로 고정)
  - ⚠️ pnpm 10 과 11 은 설정 위치가 다르다. 11 은 `pnpm-workspace.yaml`(allowBuilds), 10 은 `package.json`의 `pnpm` 필드.
- Python 3 (게이트 스크립트)

## 1. 설치 → 검증 (여기까지는 DB 없이 된다)
```bash
pnpm install
pnpm typecheck     # tsc --noEmit
pnpm test          # 권한 가드 7개
pnpm gate          # G3·G5·G7
```

## 2. 롤백 지점 (규칙_04 ②-2)
위 3개가 모두 통과한 것을 **직접 눈으로 확인한 뒤에만** 태그를 찍는다.
실행되지 않는 코드에는 태그를 찍지 않는다.
```bash
git init && git add -A && git commit -m "chore: scaffold (tRPC skeleton + migrations)"
git tag baseline-$(date +%Y%m%d)
```

## 3. 서버 띄우기 (env 필요)
```bash
cp .env.example .env      # 실제 값 입력. .env 는 커밋되지 않는다
pnpm --filter @agit/web dev
# → POST http://localhost:3000/api/trpc/workspace.listMine
```
`SUPABASE_ANON_KEY` 만 쓴다. **service_role 키는 이 저장소에 넣지 않는다** — RLS가 통째로 우회된다.

## 4. DB 마이그레이션 — **R3, 사람이 실행한다**
`packages/db/migrations/` 참조. AI·CI가 단독 실행하지 않는다.
