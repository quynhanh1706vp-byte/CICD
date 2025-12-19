# VSP_CI_OUTER

Bộ script CI “outer layer” cho VersaSecure Platform (VSP):

- `vsp_ci_outer_full_v1.sh`:
  - Nhận biến môi trường:
    - `SEC_BUNDLE_ROOT` – đường dẫn bundle VSP core (VD: /home/test/Data/SECURITY_BUNDLE)
    - `SRC_ROOT` – thư mục code cần scan (VD: $GITHUB_WORKSPACE hoặc $CI_PROJECT_DIR)
    - `VSP_CI_MAX_CRIT`, `VSP_CI_MAX_HIGH` – ngưỡng gate
  - Gọi `run_vsp_full_ext.sh` trong bundle để chạy full 8 tool.
  - Gọi `vsp_ci_gate_core_v1.sh` để quyết định PASS/FAIL.

- `vsp_ci_gate_core_v1.sh`:
  - Đọc `report/summary_unified.json` trong RUN_DIR.
  - Lấy `CRITICAL`, `HIGH`.
  - Nếu vượt ngưỡng `VSP_CI_MAX_*` -> exit code != 0 (FAIL build).
