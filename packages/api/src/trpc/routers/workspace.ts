// src/server/trpc/routers/workspace.ts
// API-02 워크스페이스/멤버 (PRD §6.3) · 화면 S-02·S-03·S-04 · 기능 F-005~F-007 계열
// ※ '한 기능씩' 원칙(VibeCoding ②-3)에 따라 이 라우터만 실제 구현하고, 나머지는 스텁이다.

import { z } from 'zod';
import { TRPCError } from '@trpc/server';
import { router, protectedProcedure, workspaceProcedure, adminProcedure } from '../trpc';

export const workspaceRouter = router({
  /** 내가 속한 워크스페이스 목록 — 로그인 직후 S-02 워크스페이스 선택 화면 */
  listMine: protectedProcedure.query(async ({ ctx }) => {
    const { data, error } = await ctx.supabase
      .from('memberships')
      .select('role, status, workspaces:workspace_id (id, name, type, logo_url)')
      .eq('user_id', ctx.userId)
      .eq('status', 'active');

    if (error) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: error.message });
    return data ?? [];
  }),

  /** 현재 워크스페이스 요약 — RLS가 남의 테넌트를 이미 잘라낸다 */
  current: workspaceProcedure.query(async ({ ctx }) => {
    const { data, error } = await ctx.supabase
      .from('workspaces')
      .select('id, name, type, logo_url')
      .eq('id', ctx.workspaceId)
      .single();

    if (error) throw new TRPCError({ code: 'NOT_FOUND', message: '워크스페이스를 찾을 수 없습니다' });
    return { ...data, myRole: ctx.wsRole };
  }),

  /** 멤버 목록 (S-04) — 운영자만. PII(이메일·이름)를 다루므로 페이지 크기를 강제한다. */
  listMembers: adminProcedure
    .input(z.object({ limit: z.number().int().min(1).max(100).default(50), offset: z.number().int().min(0).default(0) }))
    .query(async ({ ctx, input }) => {
      const { data, error } = await ctx.supabase
        .from('memberships')
        .select('user_id, role, status')
        .eq('workspace_id', ctx.workspaceId)
        .range(input.offset, input.offset + input.limit - 1);

      if (error) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: error.message });
      return data ?? [];
    }),

  /** 멤버 초대 — R2(외부 발송)·미성년 PII 관련(C-006 R3 법률검토 미완). 코드로 열지 않는다. */
  inviteMember: adminProcedure
    .input(z.object({ email: z.string().email() }))
    .mutation(() => {
      throw new TRPCError({
        code: 'NOT_IMPLEMENTED',
        message: '초대 메일 발송은 R2 — 사람 승인 플로우 확정 및 C-006 법률검토 후 구현',
      });
    }),
});
