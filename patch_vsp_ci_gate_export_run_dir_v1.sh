#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FILE="$ROOT/vsp_ci_gate_core_v1.sh"

if [ ! -f "$FILE" ]; then
  echo "[PATCH_RUN_DIR][ERR] Không tìm thấy $FILE"
  exit 1
fi

echo "[PATCH_RUN_DIR] Patching $FILE ..."

python - << 'PY'
from pathlib import Path

root = Path(__file__).resolve().parent
f = root / "vsp_ci_gate_core_v1.sh"
txt = f.read_text(encoding="utf-8")

backup = f.with_suffix(".sh.bak_export_run_dir_v1")
backup.write_text(txt, encoding="utf-8")
print("[PATCH_RUN_DIR] Backup saved as", backup)

lines = txt.splitlines()
out = []
done = False

for line in lines:
    out.append(line)
    # Tìm dòng gán RUN_DIR=...
    if not done and line.strip().startswith("RUN_DIR="):
        out.append("export RUN_DIR  # VSP: export để run_all_tools_v2.sh không bị unbound")
        done = True

if not done:
    print("[PATCH_RUN_DIR][WARN] Không tìm thấy dòng RUN_DIR=..., không sửa gì.")
else:
    new_txt = "\n".join(out) + "\n"
    f.write_text(new_txt, encoding="utf-8")
    print("[PATCH_RUN_DIR][OK] Đã chèn 'export RUN_DIR' sau dòng RUN_DIR=...")

PY
