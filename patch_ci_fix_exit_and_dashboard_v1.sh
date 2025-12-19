#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI="$ROOT/vsp_ci_outer_full_v1.sh"

if [ ! -f "$CI" ]; then
  echo "[ERR] Không tìm thấy $CI"
  exit 1
fi

backup="$CI.bak_fix_exit_$(date +%Y%m%d_%H%M%S)"
cp "$CI" "$backup"
echo "[BACKUP] $CI -> $backup"

python - << 'PY'
from pathlib import Path
import re

ci = Path("vsp_ci_outer_full_v1.sh")
txt = ci.read_text(encoding="utf-8")

# Bỏ block cũ nếu đã từng chèn
txt = re.sub(
    r'\n# --- Sync CIO dashboard view after CI run ---[\\s\\S]+?exit 0\\s*$',
    '\n',
    txt,
    flags=re.MULTILINE,
)

snippet = r'''
# --- Sync CIO dashboard view after CI run ---
cd /home/test/Data/SECURITY_BUNDLE
if [ -x bin/vsp_fix_dashboard_after_ci_v1.sh ]; then
  echo "[VSP_CI_OUTER] Sync dashboard latest_run_id (skip RUN_VSP_CI_*) ..."
  bin/vsp_fix_dashboard_after_ci_v1.sh || echo "[WARN] Dashboard fix script failed (không critical cho CI)."
else
  echo "[VSP_CI_OUTER] bin/vsp_fix_dashboard_after_ci_v1.sh not found – skip dashboard sync."
fi

exit 0
'''

# Thay đúng cái exit cuối cùng
if re.search(r'\nexit\\s+\\d+\\s*$', txt):
    txt = re.sub(r'\nexit\\s+\\d+\\s*$', snippet + '\n', txt)
else:
    txt = txt.rstrip() + '\n' + snippet + '\n'

ci.write_text(txt, encoding="utf-8")
print("[PATCH] Rewrote final exit block with dashboard sync.")
PY

echo "[OK] Patch xong."
