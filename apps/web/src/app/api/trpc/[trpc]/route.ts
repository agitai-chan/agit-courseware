// apps/web — tRPC 엔드포인트. 이 파일은 3줄이어야 한다.
// 라우터 로직은 packages/api 에만 있다(모바일과 공유). 여기 로직을 추가하지 않는다.
import { createFetchHandler } from '@agit/api';

const handler = createFetchHandler('/api/trpc');

export { handler as GET, handler as POST };
