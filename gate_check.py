#!/usr/bin/env python3
# gate_check.py — [전문-바이브코딩] 게이트 판정 (v1.0, 규칙_04 원문 복사)
# 판정: G3(비밀정보) · G5(롤백 지점) · G7(비가역 작업)
import re, sys, subprocess, pathlib

args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROOT = pathlib.Path(args[0] if args else ".")
PII_MODE = "--pii" in sys.argv
SKIP = {".git", "node_modules", "venv", ".venv", "dist", "build", "__pycache__", ".next"}
BIN = {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".zip", ".lock", ".woff", ".woff2"}

SECRET = [
    (r"sk-[A-Za-z0-9]{20,}", "OpenAI 계열 키"),
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key"),
    (r"gh[pousr]_[A-Za-z0-9]{20,}", "GitHub 토큰"),
    (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "개인키"),
    (r"(?i)\b(password|passwd|secret|api[_-]?key|token)\s*[:=]\s*['\"][^'\"]{6,}['\"]", "하드코딩 자격증명"),
]
PII = [
    (r"\b\d{6}-[1-4]\d{6}\b", "주민등록번호 형식"),
    (r"\b01[016-9]-?\d{3,4}-?\d{4}\b", "휴대전화 형식"),
    (r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", "이메일 형식"),
]

def files():
    for p in ROOT.rglob("*"):
        if p.is_file() and not (set(p.parts) & SKIP) and p.suffix.lower() not in BIN:
            yield p

def scan(patterns):
    hits = []
    for p in files():
        try:
            text = p.read_text(errors="ignore")
        except Exception:
            continue
        for pat, label in patterns:
            for m in re.finditer(pat, text):
                hits.append((label, p, text[: m.start()].count("\n") + 1))
    return hits

fails, notes = [], []

for label, p, line in scan(SECRET):
    fails.append(f"G3 비밀정보: {label} — {p}:{line}")

try:
    tags = subprocess.run(["git", "tag"], cwd=ROOT, capture_output=True, text=True, check=False).stdout.split()
    if not [t for t in tags if t.startswith(("ok-", "baseline-"))]:
        fails.append("G5 롤백 지점: 'ok-*' 또는 'baseline-*' 태그 없음 "
                     "(신규 프로젝트는 실행 가능한 scaffold에 baseline- 태그를 먼저 찍는다)")
except FileNotFoundError:
    fails.append("G5 롤백 지점: git 미설치 — 수동 사본 경로를 RUN.md에 기록했는지 사람이 확인")

MIG_DIR = re.compile(r"(migrations?|alembic[/\\]versions|prisma[/\\]migrations)", re.I)
MIG_NAME = re.compile(r"^(\d+)_(?:.+_)?(up|down)\.(sql|py|js|ts)$", re.I)
mig = [p for p in files() if MIG_DIR.search(str(p))]
ups, downs, unparsed = {}, {}, []
for p in mig:
    m = MIG_NAME.match(p.name)
    if not m:
        unparsed.append(p.name)
        continue
    (ups if m.group(2).lower() == "up" else downs).setdefault(m.group(1), []).append(p.name)
if unparsed:
    fails.append(f"G7 형식 위반(ID 해석 불가): {sorted(unparsed)} — 규칙: <숫자ID>_<설명>_up|down.<sql|py|js|ts>")
dup_u = {k: v for k, v in ups.items() if len(v) > 1}
dup_d = {k: v for k, v in downs.items() if len(v) > 1}
if dup_u:
    fails.append(f"G7 중복 up ID: {dup_u}")
if dup_d:
    fails.append(f"G7 중복 down ID: {dup_d}")
missing = sorted(set(ups) - set(downs))
if missing:
    backup = list(ROOT.rglob("backup_manifest*")) + list(ROOT.rglob("restore_test*"))
    if backup:
        notes.append(f"G7: backup manifest 발견({backup[0].name}) — 복원 테스트 결과를 사람이 확인해야 PASS")
    fails.append(f"G7 비가역: down 없는 마이그레이션 {missing} — 실행 금지")
elif ups and not (unparsed or dup_u or dup_d):
    notes.append(f"G7: 마이그레이션 {len(ups)}건 모두 down 보유 — PASS")

if PII_MODE:
    hits = scan(PII)
    print("\n[G4 PII 후보] — 스크립트는 판정하지 않는다. 사람이 확인해 seed/가상 데이터인지 판단할 것.")
    for label, p, line in hits[:50]:
        print(f"  후보 | {label} — {p}:{line}")
    print(f"  후보 총 {len(hits)}건  → G4는 사람 확인 후에만 PASS\n")

print("=" * 56)
for n in notes:
    print("NOTE |", n)
for f in fails:
    print("FAIL |", f)
print(f"판정(G3·G5·G7): {'PASS' if not fails else f'FAIL {len(fails)}건'}")
print("※ G1·G2는 러너 출력, G4는 사람 확인, G6은 DECISIONS.md로 별도 판정한다.")
sys.exit(0 if not fails else 1)
