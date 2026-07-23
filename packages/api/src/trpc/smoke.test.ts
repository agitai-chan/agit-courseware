// packages/api/src/trpc/smoke.test.ts
// G2 첫 번째 테스트 묶음 — DB 없이 도는 '권한 가드' 검증.
// 목적: Supabase RLS에 닿기 *전에* 미들웨어가 먼저 거절하는지(2중 방어의 바깥쪽)를 고정한다.
// 주의: 이 테스트가 통과해도 RLS가 검증된 것은 아니다. RLS는 실제 DB에서만 검증된다.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { SupabaseClient } from '@supabase/supabase-js';
import { createCaller, appRouter } from './routers/_app';
import { router, teacherProcedure, createCallerFactory } from './trpc';
import type { Ctx } from './context';

type Code = { code?: string };

/** 접근하면 실패하는 스텁 — "DB보다 먼저 막혔는가"를 증명한다 */
const neverCalled = new Proxy({} as SupabaseClient, {
  get() {
    throw new Error('미들웨어 통과 전에 Supabase에 접근했다 — 보안 회귀');
  },
});

/** 멤버십 1행을 돌려주는 최소 체인 스텁 (실제 DB 아님) */
function fakeSupabase(row: unknown): SupabaseClient {
  const chain: Record<string, unknown> = {};
  const self = () => chain;
  Object.assign(chain, {
    from: self,
    select: self,
    eq: self,
    range: () => Promise.resolve({ data: [], error: null }),
    maybeSingle: () => Promise.resolve({ data: row, error: null }),
    single: () => Promise.resolve({ data: row, error: null }),
  });
  return chain as unknown as SupabaseClient;
}

const ctx = (over: Partial<Ctx> = {}): Ctx => ({
  supabase: neverCalled,
  userId: null,
  workspaceId: null,
  requestId: 'test',
  ...over,
});

const MEMBER = { role: '멤버', status: 'active' };
const ADMIN = { role: '운영자', status: 'active' };

test('비로그인 → UNAUTHORIZED (DB에 닿지 않는다)', async () => {
  await assert.rejects(
    () => createCaller(ctx()).workspace.listMine(),
    (e: Code) => e.code === 'UNAUTHORIZED',
  );
});

test('x-workspace-id 없음 → BAD_REQUEST', async () => {
  await assert.rejects(
    () => createCaller(ctx({ userId: 'user-test-0001' })).workspace.current(),
    (e: Code) => e.code === 'BAD_REQUEST',
  );
});

test('멤버십 없음 → FORBIDDEN (남의 워크스페이스 차단)', async () => {
  const c = createCaller(
    ctx({ userId: 'user-test-0001', workspaceId: 'ws-0001', supabase: fakeSupabase(null) }),
  );
  await assert.rejects(() => c.workspace.current(), (e: Code) => e.code === 'FORBIDDEN');
});

test('일반 멤버가 운영자 전용 호출 → FORBIDDEN (PRD §6.4)', async () => {
  const c = createCaller(
    ctx({ userId: 'user-test-0001', workspaceId: 'ws-0001', supabase: fakeSupabase(MEMBER) }),
  );
  await assert.rejects(() => c.workspace.listMembers({}), (e: Code) => e.code === 'FORBIDDEN');
});

test('운영자는 멤버 목록 통과 (배열 반환)', async () => {
  const c = createCaller(
    ctx({ userId: 'user-test-0001', workspaceId: 'ws-0001', supabase: fakeSupabase(ADMIN) }),
  );
  assert.deepEqual(await c.workspace.listMembers({}), []);
});

test('teacherProcedure 는 C-API-01 확정 전까지 NOT_IMPLEMENTED', async () => {
  const tmp = router({ ping: teacherProcedure.query(() => 'ok') });
  const c = createCallerFactory(tmp)(
    ctx({ userId: 'user-test-0001', workspaceId: 'ws-0001', supabase: fakeSupabase(ADMIN) }),
  );
  await assert.rejects(() => c.ping(), (e: Code) => e.code === 'NOT_IMPLEMENTED');
});

test('루트 라우터 = 정본 §6.3 API 그룹 15개', () => {
  const groups = Object.keys(appRouter._def.record);
  assert.equal(groups.length, 15, `API 그룹 수가 15가 아님: ${groups.join(', ')}`);
  assert.ok(groups.includes('workspace') && groups.includes('chat'));
});
