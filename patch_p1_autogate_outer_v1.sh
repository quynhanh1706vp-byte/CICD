#!/usr/bin/env bash
set -euo pipefail
F="/home/test/Data/SECURITY-10-10-v4/ci/VSP_CI_OUTER/vsp_ci_gate_core_v1.sh"
[ -f "$F" ] || { echo "[ERR] missing $F"; exit 1; }

TS="$(date +%Y%m%d_%H%M%S)"
cp -f "$F" "$F.bak_p1_autogate_${TS}"
echo "[BACKUP] $F.bak_p1_autogate_${TS}"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("/home/test/Data/SECURITY-10-10-v4/ci/VSP_CI_OUTER/vsp_ci_gate_core_v1.sh")
t = p.read_text(encoding="utf-8", errors="ignore")

TAG = "# === VSP_P1_OUTER_AUTOGATE_V1 ==="
if TAG in t:
    print("[SKIP] already patched")
    raise SystemExit(0)

# heuristic: insert right after the runner call line that executes run_all_tools_v2.sh
m = re.search(r'(^.*run_all_tools_v2\.sh.*$)', t, flags=re.M)
if not m:
    print("[ERR] cannot find runner call line containing run_all_tools_v2.sh")
    raise SystemExit(2)

ins = m.end()
block = r'''
# === VSP_P1_OUTER_AUTOGATE_V1 ===
# Always build gate summary after runner (degrade if fails)
GATE_PY="$(find /home/test/Data/SECURITY_BUNDLE -maxdepth 6 -type f -name 'vsp_run_gate_build_v1.py' 2>/dev/null | head -n 1 || true)"
if [ -n "${GATE_PY:-}" ] && [ -f "$GATE_PY" ]; then
  echo "[P1][GATE] build: $GATE_PY $RUN_DIR"
  set +e
  python3 "$GATE_PY" "$RUN_DIR"
  RC=$?
  set -e
  if [ $RC -ne 0 ]; then
    echo "[P1][GATE][DEGRADE] rc=$RC (continue)"
  fi
else
  echo "[P1][GATE][DEGRADE] missing vsp_run_gate_build_v1.py (continue)"
fi
'''

t2 = t[:ins] + "\n" + block + "\n" + t[ins:]
p.write_text(t2, encoding="utf-8")
print("[OK] inserted autogate block")
PY

bash -n "$F"
echo "[OK] bash -n OK"
