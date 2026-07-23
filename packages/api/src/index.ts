// packages/api/src/index.ts
// 이 패키지의 유일한 공개 표면.
// apps/web(Next.js)도, Supabase Edge Function(Deno)도 여기서 handler를 받아 감싸기만 한다
// → C-API-02(배치 미결)가 확정돼도 라우터 코드는 손대지 않는다.

import { fetchRequestHandler } from '@trpc/server/adapters/fetch';
import { appRouter } from './trpc/routers/_app';
import { createContext } from './trpc/context';

export { appRouter, createCaller } from './trpc/routers/_app';
export type { AppRouter } from './trpc/routers/_app';
export { createContext } from './trpc/context';
export type { Ctx } from './trpc/context';

export function createFetchHandler(endpoint = '/api/trpc') {
  return (req: Request) =>
    fetchRequestHandler({
      endpoint,
      req,
      router: appRouter,
      createContext,
      onError({ error, path }) {
        // 프롬프트 원문·PII는 로그에 남기지 않는다 (PRD §8)
        console.error(`[trpc] ${path ?? '<no-path>'} ${error.code}`);
      },
    });
}
