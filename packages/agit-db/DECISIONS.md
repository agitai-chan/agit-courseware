# DECISIONS — 되돌리기 어려운 선택 (→ 03_History ② 로 승격)

> **승인 상태: 아래 5건 전부 사람(팀) 승인 완료 — 2026-07-23.**
> 이 시점부터 AI 제안이 아니라 팀의 결정이다. 되돌리려면 각 항목의 '재검토 트리거' 참조.

## 2026-07-23  C-DB-05: users.id = auth.users.id  **[승인됨 · 사람(팀) · 2026-07-23]**
근거: 작성_06 tRPC context 가 `supabase.auth.getUser()` 결과를 `memberships.user_id` 로 조회한다.
      두 id 체계가 분리되면 로그인 후 모든 workspaceProcedure 가 FORBIDDEN 이 된다.
버린 대안: users 독립 PK + sso_subject 조인 (조인 1회 추가, RLS 정책 복잡화)
재검토 트리거: Supabase Auth 를 쓰지 않게 될 때
반증: auth 스키마에 트리거 생성 권한이 없으면 이 구현은 실패한다 → API 레이어 upsert 로 대체

## 2026-07-23  C-DB-02 종결(승인): users 는 workspace_id 없음 + 008 에서 RLS 로 격리
근거: 전역 N–N 계정. 008 의 `users_select` 정책(본인 or 같은 워크스페이스 멤버)이 격리를 담당
주의: 007 은 users 에 RLS 를 켜지 않았다 → **008 없이 007만 적용하면 email(PII)이 노출된다**

## 2026-07-23  C-DB-01 존치(승인): class_enrollments 존치
근거: F-021 "수강생 초대·관리·미배정 식별". team_members 만으로는 팀 미배정 학생을 표현 불가
버린 대안: 삭제 후 team_members 로 대체 → F-021 수용조건 불충족

## 2026-07-23  C-DB-06(승인): Supabase CLI(`db push`) 를 쓰지 않는다
근거: CLI 는 `supabase/migrations/<timestamp>_<name>.sql` 만 인식하고 `_down.sql` 도 전진 실행한다.
      우리 G7 명명(`<숫자ID>_<설명>_up|down.sql`)과 양립하지 않는다
채택: psql 로 001→008 순차 실행
재검토: 규칙_04 G7 파서를 확장하는 H-### 변경 계약이 통과하면

## 2026-07-23  008 범위 제한(승인): 역할별 분기는 넣지 않는다
근거: C-API-01(교사/학생 판정 규칙) 미확정. 지어내면 권한 모델 전체가 오염된다
현재: 운영자=쓰기 / 멤버=읽기 2단계 + 개인·팀 소유권만 강제. 교사/학생 세분화는 009

## 의존성 (G6)
| 항목 | 버전 | 라이선스 | 사유 |
|:--|:--|:--|:--|
| PostgreSQL | 16.2 (샌드박스) / Supabase 16 | PostgreSQL License | 정본 §6.3 |
| pgvector | 0.6.0 | PostgreSQL License | hnsw 인덱스는 >=0.5 필요 (005) |
| pglast | 8.2 | GPL-3.0 (개발 도구, 배포물 아님) | SQL 문법 파싱 검증 |
