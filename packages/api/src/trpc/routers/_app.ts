// src/server/trpc/routers/_app.ts
// 루트 라우터 = PRD §6.3 API 그룹 15개와 1:1. 네임스페이스를 임의로 늘리지 않는다.
// 채워진 것: workspace(API-02) 뿐. 나머지는 빈 라우터 스텁 — 한 세션 = 한 그룹으로 채운다.

import { router, createCallerFactory } from '../trpc';
import { workspaceRouter } from './workspace';

const todo = () => router({}); // 빈 라우터 = "아직 계약 없음"을 타입으로 드러낸다

export const appRouter = router({
  auth: todo(),          // API-01 인증            · F-001~F-003 (Google SSO, 미성년 동의)
  workspace: workspaceRouter, // API-02 워크스페이스/멤버 · S-02~S-04            ← 구현됨
  course: todo(),        // API-03 코스/모듈/태스크 · F-008~F-014 · S-05~S-12
  class: todo(),         // API-04 클래스 개설(복제) · F-015 스냅샷 복제 · S-13
  enrollment: todo(),    // API-05 수강생/팀        · F-021·F-023 (C-DB-01 선행)
  assignment: todo(),    // API-06 할당            · F-022 부분 할당
  chat: todo(),          // API-07 채팅/프롬프트+PIQ · F-030·F-037·F-038 (인젝션 방어 F-047 필수)
  submission: todo(),    // API-08 결과물/Evidence · F-040 (R2)
  money: todo(),         // API-09 머니게임 정산    · F-020 · v2.0
  peerFeedback: todo(),  // API-10 다면평가        · F-041 · v2.0
  workspaceNote: todo(), // API-11 노트/파일       · F-045·F-046 (개인·전역)
  board: todo(),         // API-12 게시판          · F-024 · v2.0
  ops: todo(),           // API-13 운영관리        · F-025 · v2.0
  presentation: todo(),  // API-14 발표 생성/내보내기 · F-042·F-043 · v2.0
  promptPick: todo(),    // API-15 우수 프롬프트 추천 · F-049 · v2.0
});

/** 클라이언트(Web·Expo)가 import 하는 유일한 타입. 서버 코드는 넘어가지 않는다. */
/** 테스트·서버 내부 호출용 (HTTP를 타지 않고 같은 미들웨어를 그대로 통과한다) */
export const createCaller = createCallerFactory(appRouter);

export type AppRouter = typeof appRouter;
