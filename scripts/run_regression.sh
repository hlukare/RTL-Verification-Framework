#!/usr/bin/env bash
set -euo pipefail

simulator="${1:-iverilog}"
shift || true
tests=("$@")

if [[ ${#tests[@]} -eq 0 ]]; then
  tests=(fifo_tb arbiter_tb uart_tx_tb)
fi

mkdir -p build/logs build/waves build/coverage

status=0
for test in "${tests[@]}"; do
  echo "[RUN] ${test} (${simulator})"
  if [[ "${simulator}" == "iverilog" ]]; then
    if ! ./scripts/run_iverilog.sh "${test}"; then
      status=1
    fi
  else
    echo "[ERROR] Unsupported simulator: ${simulator}"
    status=1
  fi
done

if [[ ${status} -eq 0 ]]; then
  echo "[PASS] Regression completed"
else
  echo "[FAIL] Regression completed with failures"
fi

exit "${status}"
