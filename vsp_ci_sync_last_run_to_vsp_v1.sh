#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[VSP_CI_SYNC]"
log() { echo "${LOG_PREFIX} $*"; }

# Root chứa out_ci trong repo chính
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_ROOT="${REPO_ROOT}/out_ci"

# BUNDLE_ROOT = engine VSP (SECURITY_BUNDLE)
BUNDLE_ROOT="${VSP_BUNDLE_ROOT:-/home/test/Data/SECURITY_BUNDLE}"
VSP_OUT_ROOT="${BUNDLE_ROOT}/out"

log "REPO_ROOT   = ${REPO_ROOT}"
log "CI_ROOT     = ${CI_ROOT}"
log "BUNDLE_ROOT = ${BUNDLE_ROOT}"
log "VSP_OUT_ROOT= ${VSP_OUT_ROOT}"

if [[ ! -d "${CI_ROOT}" ]]; then
  log "ERROR: Không tìm thấy CI_ROOT: ${CI_ROOT}"
  exit 1
fi

mkdir -p "${VSP_OUT_ROOT}"

# Tìm CI run mới nhất
LATEST_RUN="$(ls -1dt "${CI_ROOT}"/VSP_CI_* 2>/dev/null | head -n1 || true)"

if [[ -z "${LATEST_RUN}" ]]; then
  log "ERROR: Không tìm thấy thư mục VSP_CI_* nào trong ${CI_ROOT}"
  exit 2
fi

if [[ ! -d "${LATEST_RUN}" ]]; then
  log "ERROR: LATEST_RUN không phải thư mục: ${LATEST_RUN}"
  exit 3
fi

RUN_NAME="$(basename "${LATEST_RUN}")"
DEST_RUN="${VSP_OUT_ROOT}/RUN_${RUN_NAME}"

log "LATEST_RUN = ${LATEST_RUN}"
log "RUN_NAME   = ${RUN_NAME}"
log "DEST_RUN   = ${DEST_RUN}"

mkdir -p "${DEST_RUN}"

log "Đồng bộ CI run sang VSP out/ ..."
rsync -av --delete "${LATEST_RUN}/" "${DEST_RUN}/"

# Optional: đọc run_id từ summary_unified.json nếu có
SUMMARY_JSON="${DEST_RUN}/report/summary_unified.json"
if [[ -f "${SUMMARY_JSON}" ]]; then
  RUN_ID_JSON="$(jq -r '.run_id // empty' "${SUMMARY_JSON}" 2>/dev/null || true)"
  if [[ -n "${RUN_ID_JSON}" ]]; then
    log "run_id trong summary_unified.json: ${RUN_ID_JSON}"
  fi
fi

# OPTIONAL: gọi script rebuild dashboard nếu có
DASH_SCRIPT_DEFAULT="${BUNDLE_ROOT}/bin/vsp_build_dashboard_extras_v2.sh"
DASH_SCRIPT="${VSP_DASHBOARD_REBUILD:-${DASH_SCRIPT_DEFAULT}}"

if [[ -x "${DASH_SCRIPT}" ]]; then
  log "Gọi script rebuild dashboard: ${DASH_SCRIPT}"
  set +e
  "${DASH_SCRIPT}"
  RC_DASH=$?
  set -e
  if [[ ${RC_DASH} -ne 0 ]]; then
    log "WARN: Dashboard rebuild script trả về RC=${RC_DASH}"
  else
    log "Dashboard rebuild OK."
  fi
else
  log "INFO: Không tìm thấy hoặc không chạy được DASH_SCRIPT: ${DASH_SCRIPT}"
  log "      (Set ENV VSP_DASHBOARD_REBUILD nếu cần trỏ script khác)."
fi

log "Hoàn tất sync CI run sang VSP UI."
