#!/usr/bin/env bash
set -euo pipefail

F="./vsp_ci_outer_full_v1.sh"
BK="${F}.bak_autosync_v1_$(date +%Y%m%d_%H%M%S)"
cp "$F" "$BK"
echo "[BACKUP] $BK"

python3 - << 'PY'
from pathlib import Path
import re

f = Path("./vsp_ci_outer_full_v1.sh")
txt = f.read_text(encoding="utf-8", errors="ignore")

if "VSP_CI_SYNC" in txt and "vsp_ci_sync_to_vsp_v1.sh" in txt:
    print("[SKIP] autosync seems already present")
    raise SystemExit(0)

# Chèn trước khi script kết thúc: sau phần summary / trước exit
# Tìm anchor: dòng ghi "=== VSP CI OUTER:" hoặc ngay trước "exit $RC"
m = re.search(r'(?m)^\s*echo\s+"\[VSP_CI_OUTER\].*=== VSP CI OUTER:.*$', txt)
insert_pos = m.end() if m else len(txt)

block = r'''

# === AUTO SYNC TO VSP CORE (commercial flow) ===
echo "[VSP_CI_OUTER] Auto-sync CI RUN_DIR -> VSP core out/ (best-effort)"
SYNC="${BUNDLE_ROOT}/bin/vsp_ci_sync_to_vsp_v1.sh"
if [ -x "$SYNC" ]; then
  "$SYNC" "$RUN_DIR" || echo "[VSP_CI_OUTER] WARN: sync failed (ignored)"
else
  echo "[VSP_CI_OUTER] WARN: sync script not found: $SYNC"
fi
# === END AUTO SYNC ===

'''

txt2 = txt[:insert_pos] + block + txt[insert_pos:]
f.write_text(txt2, encoding="utf-8")
print("[OK] injected autosync block into vsp_ci_outer_full_v1.sh")
PY

bash -n "$F" && echo "[OK] bash syntax OK"
