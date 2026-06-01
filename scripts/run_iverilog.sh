#!/usr/bin/env bash
set -euo pipefail

test="${1:?Usage: scripts/run_iverilog.sh <fifo_tb|arbiter_tb|uart_tx_tb>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sim_dir="${repo_root}/sim"
build_dir="${repo_root}/build"

mkdir -p "${build_dir}/logs" "${build_dir}/waves" "${build_dir}/bin"

if [[ ! -f "${sim_dir}/${test}.f" ]]; then
  echo "[ERROR] Missing file list: sim/${test}.f"
  exit 1
fi

pushd "${repo_root}" >/dev/null

iverilog -g2012 -DIVERILOG -Wall -o "${build_dir}/bin/${test}.vvp" -f "${sim_dir}/${test}.f" \
  2>&1 | tee "${build_dir}/logs/${test}_compile.log"

vvp "${build_dir}/bin/${test}.vvp" \
  2>&1 | tee "${build_dir}/logs/${test}_sim.log"

popd >/dev/null

echo "[DONE] ${test}"
