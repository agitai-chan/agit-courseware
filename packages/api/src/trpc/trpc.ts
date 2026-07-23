// src/server/trpc/trpc.ts
// 절차(procedure) 사다리: public → protected(로그인) → workspace(멤버십) → admin(운영자)
// 2중 방어 — 바깥쪽=여기 미들웨어(빠른 거절·에러 메시지), 안쪽=Supabase RLS(최종 강제).
// 미들웨어는 RLS를 대체하지 않는다. RLS가 없으면 이 파일은 보안이 아니다.

import { initTRPC, TRPCError } from '@trpc/server';
import superjson from 'superjson';
import type { Ctx } from './context';

/** 001_extensions_and_enums_up.sql 의 ws_role (작성_05) — 정본 E-02 */
export type WsRole = '운영자' | '멤버';

const t = initTRPC.context<Ctx>().create({
  transformer: superjson, // Date·Map 등을 클라이언트까지 타입 그대로 (v11: 클라이언트 링크에도 동일 지정)
});

export const router = t.router;
export const createCallerFactory = t.createCallerFactory; // 서버 내부 호출·테스트용
export const middleware = t.middleware;

/** 로그인 전에도 열리는 표면 — API-01 뿐. 그 외에는 쓰지 않는다. */
export const publicProcedure = t.procedure;

const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.userId) throw new TRPCError({ code: 'UNAUTHORIZED', message: '로그인이 필요합니다' });
  return next({ ctx: { ...ctx, userId: ctx.userId } });
});

/** 로그인 확인만 (워크스페이스 무관: 내 노트·내 파일 등 전역 개인 리소스) */
export const protectedProcedure = t.procedure.use(isAuthed);

const inWorkspace = t.middleware(async ({ ctx, next }) => {
  if (!ctx.workspaceId) {
    throw new TRPCError({ code: 'BAD_REQUEST', message: 'x-workspace-id 헤더가 없습니다' });
  }
  const { data, error } = await ctx.supabase
    .from('memberships')
    .select('role, status')
    .eq('workspace_id', ctx.workspaceId)
    .eq('user_id', ctx.userId!)
    .maybeSingle();

  if (error) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: '멤버십 조회 실패' });
  if (!data || data.status !== 'active') throw new TRPCError({ code: 'FORBIDDEN' });

  return next({
    ctx: { ...ctx, workspaceId: ctx.workspaceId!, wsRole: data.role as WsRole },
  });
});

/** 워크스페이스 스코프가 필요한 모든 API의 기본값 */
export const workspaceProcedure = protectedProcedure.use(inWorkspace);

/** 운영자 전용 — PRD §6.4 Workspace ● / Course ● */
export const adminProcedure = workspaceProcedure.use(({ ctx, next }) => {
  if (ctx.wsRole !== '운영자') {
    throw new TRPCError({ code: 'FORBIDDEN', message: '운영자만 가능합니다' });
  }
  return next();
});

/**
 * [열림 C-API-01] 교사/학생 절차는 아직 만들 수 없다.
 * memberships.role 은 운영자/멤버 2값(정본 E-02)인데, 권한 매트릭스(PRD §6.4)는
 * 운영자/교사/학생 3역할이다. 교사 = classes.teacher_id, 학생 = class_enrollments(C-DB-01 미확정)
 * 로 '파생'해야 하는데 그 규칙이 정본에 없다 → 지어내지 않고 막아 둔다.
 */
const notYet = t.middleware(() => {
  throw new TRPCError({
    code: 'NOT_IMPLEMENTED',
    message: 'C-API-01 미확정: 교사/학생 판정 규칙을 정본에서 확정한 뒤 구현',
  });
});
export const teacherProcedure = workspaceProcedure.use(notYet);
export const studentProcedure = workspaceProcedure.use(notYet);
