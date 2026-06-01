#!/usr/bin/env bash
set -euo pipefail

test="${1:?Usage: scripts/open_wave.sh <fifo_tb|arbiter_tb|uart_tx_tb>}"
wave="build/waves/${test}.vcd"

if [[ ! -f "${wave}" ]]; then
  echo "[ERROR] Missing ${wave}. Run the regression first."
  exit 1
fi

gtkwave "${wave}" "docs/waveforms/${test}.gtkw" >/dev/null 2>&1 &

