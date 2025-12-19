#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

F="vsp_ci_outer_full_v1.sh"
[ -f "$F" ] || { echo "[ERR] missing $PWD/$F"; exit 1; }

TS="$(date +%Y%m%d_%H%M%S)"
cp -f "$F" "$F.bak_runnerlog_v1_${TS}"
echo "[BACKUP] $F.bak_runnerlog_v1_${TS}"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("vsp_ci_outer_full_v1.sh")
txt = p.read_text(encoding="utf-8", errors="replace")

# remove old block if exists
txt = re.sub(r"# === VSP_CI_OUTER_RUNNERLOG_V1 ===[\s\S]*?# === END VSP_CI_OUTER_RUNNERLOG_V1 ===\n?", "", txt, flags=re.M)

block = r"""
# === VSP_CI_OUTER_RUNNERLOG_V1 ===
# Ensure runner.log exists and capture ALL stdout/stderr for status parsing
if [ -n "${RUN_DIR:-}" ]; then
  mkdir -p "$RUN_DIR" || true
  RUNNER_LOG="${RUN_DIR}/runner.log"
  : > "$RUNNER_LOG" || true
  exec > >(tee -a "$RUNNER_LOG") 2>&1
  echo "[VSP_CI_OUTER_RUNNERLOG_V1] runner_log=$RUNNER_LOG"
fi
# === END VSP_CI_OUTER_RUNNERLOG_V1 ===
"""

# inject after RUN_DIR is set and directory is created
# common patterns: mkdir -p "$RUN_DIR" or RUN_DIR=...
m = re.search(r'^\s*mkdir\s+-p\s+"\$RUN_DIR"\s*.*$', txt, flags=re.M)
if m:
    ins = m.end()
    txt = txt[:ins] + "\n" + block + txt[ins:]
else:
    m = re.search(r'^\s*RUN_DIR=.*$', txt, flags=re.M)
    if not m:
        raise SystemExit("[ERR] cannot find RUN_DIR/mkdir -p \"$RUN_DIR\" to hook")
    ins = m.end()
    txt = txt[:ins] + "\n" + block + txt[ins:]

p.write_text(txt, encoding="utf-8")
print("[OK] injected runner.log tee block")
PY

bash -n "$F"
echo "[OK] bash -n OK"
