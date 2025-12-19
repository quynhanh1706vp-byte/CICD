#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

UI_DIR="${VSP_UI_DIR:-/home/test/Data/SECURITY_BUNDLE/ui}"

echo "== P1 RELEASE (OUTER wrapper) =="
echo "[ROOT]  $ROOT"
echo "[UI]    $UI_DIR"

# (1) Run OUTER CI pipeline (gate/build/pack whatever you already have)
if [ -x "./vsp_ci_outer_full_v1.sh" ]; then
  echo "== (1) run: vsp_ci_outer_full_v1.sh =="
  ./vsp_ci_outer_full_v1.sh
elif [ -x "./vsp_ci_gate_core_v1.sh" ]; then
  echo "== (1) run: vsp_ci_gate_core_v1.sh =="
  ./vsp_ci_gate_core_v1.sh
else
  echo "[ERR] missing CI runner: vsp_ci_outer_full_v1.sh / vsp_ci_gate_core_v1.sh"
  exit 2
fi

# (2) If UI exists, run UI release pack (if script exists)
UI_REL_DIR=""
if [ -d "$UI_DIR" ]; then
  if [ -x "$UI_DIR/bin/p1_release_gate_and_pack_v1.sh" ]; then
    echo "== (2) run UI release pack =="
    ( cd "$UI_DIR" && ./bin/p1_release_gate_and_pack_v1.sh )
  else
    echo "[WARN] UI release script not found: $UI_DIR/bin/p1_release_gate_and_pack_v1.sh"
  fi

  # (3) Copy UI release outputs -> OUTER/out_ci/releases (for GitHub artifact upload)
  if ls "$UI_DIR"/out_ci/releases/REL_* >/dev/null 2>&1; then
    UI_REL_DIR="$(ls -1dt "$UI_DIR"/out_ci/releases/REL_* | head -n1 || true)"
    echo "[INFO] UI_REL_DIR=$UI_REL_DIR"

    mkdir -p out_ci/releases

    # copy tgz (if any)
    if ls "$UI_DIR"/out_ci/releases/VSP_UI_RELEASE_*.tgz >/dev/null 2>&1; then
      cp -f "$UI_DIR"/out_ci/releases/VSP_UI_RELEASE_*.tgz out_ci/releases/ 2>/dev/null || true
    fi

    # copy latest REL_* folder
    BN="$(basename "$UI_REL_DIR")"
    rm -rf "out_ci/releases/$BN" 2>/dev/null || true
    cp -a "$UI_REL_DIR" "out_ci/releases/$BN"
    echo "[OK] copied UI REL -> out_ci/releases/$BN"
  else
    echo "[WARN] UI has no out_ci/releases/REL_* yet"
  fi
else
  echo "[WARN] UI_DIR not found: $UI_DIR (skip UI pack/copy)"
fi

echo "== (4) list OUTER out_ci/releases (top) =="
ls -la out_ci/releases || true
ls -1dt out_ci/releases/REL_* 2>/dev/null | head -n 5 || true
ls -1t  out_ci/releases/VSP_UI_RELEASE_*.tgz 2>/dev/null | head -n 5 || true

echo "== DONE =="
