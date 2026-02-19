# ------------------------------------------------------------
# Simple top-level Makefile (SystemVerilog branch)
# ------------------------------------------------------------

.PHONY: sim clean help

help:
	@echo "Available targets:"
	@echo "  make sim    - build and run DOT engine simulation (Verilator)"
	@echo "  make clean  - remove simulation artifacts"

sim:
	@./scripts/build.sh

clean:
	@rm -rf sim/
