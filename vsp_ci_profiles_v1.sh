#!/usr/bin/env bash
# Map profile CI → on/off KICS & CodeQL

VSP_CI_PROFILE="${VSP_CI_PROFILE:-EXT}"

echo "[VSP_CI_PROFILE] Profile = ${VSP_CI_PROFILE}"

case "${VSP_CI_PROFILE}" in
  FAST)
    # Nhanh: tắt KICS + CodeQL (chỉ Gitleaks, Semgrep, Bandit, Trivy, Syft, Grype)
    export VSP_SKIP_KICS=1
    export VSP_SKIP_CODEQL=1
    echo "[VSP_CI_PROFILE] FAST -> VSP_SKIP_KICS=1, VSP_SKIP_CODEQL=1"
    ;;
  EXT|"")
    # Mặc định: bật đủ 8 tools
    unset VSP_SKIP_KICS
    unset VSP_SKIP_CODEQL
    echo "[VSP_CI_PROFILE] EXT -> KICS + CodeQL ENABLED"
    ;;
  AGGR)
    # Aggressive: vẫn bật KICS + CodeQL, sau này có thể nâng thêm rule-set
    unset VSP_SKIP_KICS
    unset VSP_SKIP_CODEQL
    echo "[VSP_CI_PROFILE] AGGR -> KICS + CodeQL ENABLED (aggressive mode placeholder)"
    ;;
  *)
    echo "[VSP_CI_PROFILE][WARN] Profile không hỗ trợ: ${VSP_CI_PROFILE}, dùng EXT."
    unset VSP_SKIP_KICS
    unset VSP_SKIP_CODEQL
    ;;
esac
