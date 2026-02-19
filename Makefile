# ------------------------------------------------------------
# Simple top-level Makefile
# ------------------------------------------------------------

.PHONY: sim clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  make sim    - build and run DOT engine simulation"
	@echo "  make clean  - remove simulation artifacts"

# Run simulation
sim:
	@./scripts/build.sh

# Clean generated files
clean:
	@rm -rf sim/

