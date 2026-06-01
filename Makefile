SHELL := /bin/bash

TESTS ?= fifo_tb arbiter_tb uart_tx_tb
SIM ?= iverilog

.PHONY: help regress iverilog verilator lint clean tree

help:
	@echo "Targets:"
	@echo "  make regress              Run all tests with Icarus Verilog"
	@echo "  make iverilog TEST=fifo_tb Run one test with Icarus Verilog"
	@echo "  make verilator            Run Verilator lint on RTL"
	@echo "  make lint                 Alias for Verilator lint"
	@echo "  make clean                 Remove generated simulator output"

regress:
	@./scripts/run_regression.sh $(SIM) $(TESTS)

iverilog:
	@if [[ -z "$(TEST)" ]]; then echo "Set TEST=fifo_tb|arbiter_tb|uart_tx_tb"; exit 1; fi
	@./scripts/run_iverilog.sh $(TEST)

verilator lint:
	@./scripts/run_verilator_lint.sh

tree:
	@find . \( -path ./.git -o -path ./build -o -path ./obj_dir \) -prune -o -maxdepth 3 -type f -print | sort

clean:
	@rm -rf build obj_dir *.vcd *.fst *.vvp *.log coverage.dat coverage.info coverage
