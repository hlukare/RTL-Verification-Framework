#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${repo_root}/build"

mkdir -p "${build_dir}/logs"

lint_one() {
  local top="$1"
  local rtl="$2"
  verilator --lint-only --sv -Wall \
    --top-module "${top}" \
    -I"${repo_root}/rtl/common" \
    "${repo_root}/rtl/common/rvf_pkg.sv" \
    "${rtl}"
}

{
  lint_one sync_fifo "${repo_root}/rtl/fifo/sync_fifo.sv"
  lint_one round_robin_arbiter "${repo_root}/rtl/arbiter/round_robin_arbiter.sv"
  lint_one uart_tx "${repo_root}/rtl/uart/uart_tx.sv"
} 2>&1 | tee "${build_dir}/logs/verilator_lint.log"

echo "[DONE] Verilator RTL lint"
