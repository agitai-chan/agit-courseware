# @agit/mobile (Expo · React Native) — v1.0 후반 착수

아직 비어 있다. 착수 시점에 `packages/api` 의 `AppRouter` 타입만 import 한다:

```ts
import type { AppRouter } from '@agit/api';
```

서버 코드는 넘어오지 않는다(타입만 넘어온다). 이 구조가 성립하지 않으면
tRPC 선택의 근거(C-001 프론트 분리 + TS 단일 계약)가 무너진다 → 그때는 OpenAPI 표면을 검토한다.
