# RTL Verification Framework

SystemVerilog RTL and testbench examples for verifying small digital IP blocks
with an open-source tool flow.

The project uses:

- `iverilog` for simulation
- `verilator` for RTL lint
- `gtkwave` for waveform debug

## Blocks

| Block | RTL | Testbench | What is verified |
| --- | --- | --- | --- |
| Synchronous FIFO | `rtl/fifo/sync_fifo.sv` | `tb/fifo/fifo_tb.sv` | Ordering, full/empty flags, overflow, underflow, simultaneous read/write |
| Round-robin arbiter | `rtl/arbiter/round_robin_arbiter.sv` | `tb/arbiter/arbiter_tb.sv` | One-hot grants, fairness rotation, request masking, ready backpressure |
| UART transmitter | `rtl/uart/uart_tx.sv` | `tb/uart/uart_tx_tb.sv` | Start bit, data bits, stop bit, busy/done timing |

SVA checkers are kept under `assertions/`. The default Icarus Verilog run uses
scoreboards and waveform checks because Icarus has limited SVA support.

## Layout

```text
.
├── assertions/       SVA checkers
├── docs/waveforms/   GTKWave save files
├── rtl/              Design sources
├── scripts/          Regression, lint, and waveform helpers
├── sim/              Icarus Verilog file lists
└── tb/               SystemVerilog testbenches
```

## Requirements

Ubuntu/Debian:

```bash
sudo apt-get install iverilog verilator gtkwave make
```

Check tools:

```bash
iverilog -V
verilator --version
gtkwave --version
```

## Run

Run the full simulation regression:

```bash
make regress
```

Run one test:

```bash
make iverilog TEST=fifo_tb
make iverilog TEST=arbiter_tb
make iverilog TEST=uart_tx_tb
```

Run Verilator lint:

```bash
make verilator
```

Open a waveform after simulation:

```bash
./scripts/open_wave.sh fifo_tb
./scripts/open_wave.sh arbiter_tb
./scripts/open_wave.sh uart_tx_tb
```

Clean generated files:

```bash
make clean
```

## Inputs And Outputs

The user does not provide runtime input. Testbenches generate DUT stimulus.

FIFO inputs:

- `clk`, `rst_n`
- `wr_en`, `rd_en`
- `din`

FIFO outputs:

- `dout`
- `full`, `empty`
- `almost_full`, `almost_empty`
- `count`

Arbiter inputs:

- `clk`, `rst_n`
- `req`
- `ready`

Arbiter outputs:

- `grant`
- `valid`

UART TX inputs:

- `clk`, `rst_n`
- `start`
- `data_i`

UART TX outputs:

- `tx`
- `busy`
- `done`

Simulation artifacts:

```text
build/bin/*.vvp
build/logs/*_compile.log
build/logs/*_sim.log
build/logs/verilator_lint.log
build/waves/*.vcd
```

Expected successful regression:

```text
[PASS] sync_fifo completed with no scoreboard errors
[PASS] round_robin_arbiter completed with no scoreboard errors
[PASS] uart_tx completed with no scoreboard errors
[PASS] Regression completed
```

## Verification Approach

Each testbench includes:

- reset checks
- directed corner cases
- randomized stimulus
- reference-model or scoreboard checks
- VCD dump generation for GTKWave

The SVA files document protocol-level properties and can be reused with tools
that support the required assertion subset.
