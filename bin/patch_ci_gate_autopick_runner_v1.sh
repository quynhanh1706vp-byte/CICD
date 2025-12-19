#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

F="vsp_ci_gate_core_v1.sh"
[ -f "$F" ] || { echo "[ERR] missing $PWD/$F"; exit 1; }

TS="$(date +%Y%m%d_%H%M%S)"
cp -f "$F" "$F.bak_autorunner_${TS}"
echo "[BACKUP] $F.bak_autorunner_${TS}"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("vsp_ci_gate_core_v1.sh")
txt = p.read_text(encoding="utf-8", errors="replace")

if "VSP_CI_GATE_AUTOPICK_RUNNER_V1" in txt:
    print("[OK] already patched: VSP_CI_GATE_AUTOPICK_RUNNER_V1")
    raise SystemExit(0)

block = r'''
# === VSP_CI_GATE_AUTOPICK_RUNNER_V1 ===
# Prefer ENV VSP_RUNNER; fallback to SECURITY_BUNDLE runner
if [ -n "${VSP_RUNNER:-}" ] && [ -x "${VSP_RUNNER}" ]; then
  RUNNER="${VSP_RUNNER}"
elif [ -x "/home/test/Data/SECURITY_BUNDLE/bin/run_all_tools_v2.sh" ]; then
  RUNNER="/home/test/Data/SECURITY_BUNDLE/bin/run_all_tools_v2.sh"
elif [ -n "${BUNDLE_ROOT:-}" ] && [ -x "${BUNDLE_ROOT}/SECURITY_BUNDLE/bin/run_all_tools_v2.sh" ]; then
  RUNNER="${BUNDLE_ROOT}/SECURITY_BUNDLE/bin/run_all_tools_v2.sh"
fi
echo "[VSP_CI_GATE_AUTOPICK_RUNNER_V1] RUNNER=${RUNNER}"
# === END VSP_CI_GATE_AUTOPICK_RUNNER_V1 ===
'''

# inject right after first RUNNER= assignment, else after RUN_ID/RUN_DIR area
m = re.search(r'^\s*RUNNER\s*=\s*.*$', txt, flags=re.M)
if m:
    ins = m.end()
    txt = txt[:ins] + "\n" + block + txt[ins:]
else:
    # try after RUN_DIR=
    m = re.search(r'^\s*RUN_DIR\s*=\s*.*$', txt, flags=re.M)
    if not m:
        raise SystemExit("[ERR] cannot find RUNNER= or RUN_DIR= to hook")
    ins = m.end()
    txt = txt[:ins] + "\n" + block + txt[ins:]

p.write_text(txt, encoding="utf-8")
print("[OK] injected VSP_CI_GATE_AUTOPICK_RUNNER_V1")
PY

bash -n "$F"
echo "[OK] bash -n OK"
