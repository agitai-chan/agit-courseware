// src/server/trpc/context.ts
// AGIT tRPC Context — 요청 1건 = 그 사용자의 권한으로 만든 Supabase 클라이언트 1개.
// 원칙(PRD §8): 라우터는 service_role 키를 쓰지 않는다. anon key + 사용자 JWT 로만 접근해야
//              모든 쿼리에 RLS(테넌트·팀 격리)가 살아 있다. service_role 은 RLS를 우회한다.

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { FetchCreateContextFnOptions } from '@trpc/server/adapters/fetch';

export interface Ctx {
  supabase: SupabaseClient;
  /** Supabase Auth user id (= users.id). 비로그인이면 null */
  userId: string | null;
  /** x-workspace-id 헤더. 멀티테넌시 스코프 (PRD §6.2 workspace_id) */
  workspaceId: string | null;
  requestId: string;
}

function requireEnv(name: string): string {
  // [열림 C-API-02] Vercel(Next.js Node/Edge)이면 process.env,
  //                Supabase Edge Function(Deno)이면 Deno.env.get — 배치 확정 후 한 곳으로 통일한다.
  const v = process.env[name];
  if (!v) throw new Error(`환경변수 없음: ${name}`);
  return v;
}

export async function createContext({ req }: FetchCreateContextFnOptions): Promise<Ctx> {
  const authHeader = req.headers.get('authorization') ?? '';
  const accessToken = authHeader.toLowerCase().startsWith('bearer ')
    ? authHeader.slice(7).trim()
    : null;

  const supabase = createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_ANON_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : {} },
  });

  let userId: string | null = null;
  if (accessToken) {
    const { data, error } = await supabase.auth.getUser(accessToken);
    if (!error) userId = data.user?.id ?? null;
  }

  return {
    supabase,
    userId,
    workspaceId: req.headers.get('x-workspace-id'),
    requestId: crypto.randomUUID(),
  };
}
