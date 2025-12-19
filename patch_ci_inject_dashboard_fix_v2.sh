#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI="$ROOT/vsp_ci_outer_full_v1.sh"

if [ ! -f "$CI" ]; then
  echo "[ERR] Không tìm thấy $CI"
  exit 1
fi

# Nếu đã chèn rồi thì thôi
if grep -q "vsp_fix_dashboard_after_ci_v1.sh" "$CI"; then
  echo "[INFO] Đã có call vsp_fix_dashboard_after_ci_v1.sh trong $CI, bỏ qua."
  exit 0
fi

backup="$CI.bak_inject_dashboard_fix_$(date +%Y%m%d_%H%M%S)"
cp "$CI" "$backup"
echo "[BACKUP] $CI -> $backup"

python - << 'PY'
from pathlib import Path

ci = Path("vsp_ci_outer_full_v1.sh")
txt = ci.read_text(encoding="utf-8")

BUNDLE_ROOT = "/home/test/Data/SECURITY_BUNDLE"

snippet = f'''
# --- Sync CIO dashboard view after CI run ---
cd {BUNDLE_ROOT}
if [ -x bin/vsp_fix_dashboard_after_ci_v1.sh ]; then
  echo "[VSP_CI_OUTER] Sync dashboard latest_run_id (skip RUN_VSP_CI_*) ..."
  bin/vsp_fix_dashboard_after_ci_v1.sh || echo "[WARN] Dashboard fix script failed (không critical cho CI)."
else
  echo "[VSP_CI_OUTER] bin/vsp_fix_dashboard_after_ci_v1.sh not found – skip dashboard sync."
fi
'''

idx = txt.rfind("\\nexit ")
if idx != -1:
    new_txt = txt[:idx] + snippet + "\\n" + txt[idx+1:]
else:
    new_txt = txt.rstrip() + "\\n" + snippet + "\\n"

ci.write_text(new_txt, encoding="utf-8")
print("[PATCH] Injected dashboard fix block into vsp_ci_outer_full_v1.sh")
PY

echo "[OK] Patch xong."
