#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
n=$(ls migrations/*_up.sql | wc -l)
[ "$n" -eq 8 ] || { echo "STOP: up 파일 ${n}개 (기대 8) — 저장소를 잘못 짚었다"; exit 1; }
for f in migrations/00{1,2,3,4,5,6,7,8}_*_up.sql; do
  echo "=== $f"
  psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$f"
done
echo "APPLY OK"