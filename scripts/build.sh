#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Paths (relative to repo root)
# ------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL_DIR="$ROOT_DIR/rtl"
TB_DIR="$ROOT_DIR/tb"
SIM_DIR="$ROOT_DIR/sim"
EXT_DIR="$ROOT_DIR/external/pipelined-mac-core"

# ------------------------------------------------------------
# Simulation settings
# ------------------------------------------------------------
TOP="tb_dot_engine"
STOP_TIME="${STOP:-500}"  # Verilator uses time units in simulation, keep as numeric cycles-ish in TB
VCD_FILE="$SIM_DIR/dot_engine_sim.vcd"

# Sources
DOT_PKG="$RTL_DIR/dot_types_pkg.sv"
DOT_DUT="$RTL_DIR/dot_engine.sv"
MAC_SRC="$EXT_DIR/rtl/mac.sv"
TB_SRC="$TB_DIR/tb_dot_engine.sv"

# ------------------------------------------------------------
# Prepare simulation directory
# ------------------------------------------------------------
mkdir -p "$SIM_DIR"
rm -rf "$SIM_DIR/obj_dir" "$VCD_FILE"

echo "[INFO] Simulation directory: $SIM_DIR"

# ------------------------------------------------------------
# Build + run with Verilator
# ------------------------------------------------------------
# Notes:
# - --binary builds and runs a standalone simulation executable (no C++ harness needed)
# - --trace enables VCD tracing ($dumpfile/$dumpvars in TB)
echo "[INFO] Building (Verilator)..."
verilator -Wno-fatal -Wall --binary -sv --trace \
  -o "$TOP" \
  -Mdir "$SIM_DIR/obj_dir" \
  -CFLAGS "-O2" \
  "$DOT_PKG" "$MAC_SRC" "$DOT_DUT" "$TB_SRC"

echo "[INFO] Running simulation..."
"$SIM_DIR/obj_dir/$TOP"

# Verilator writes VCD in the current working directory by default; move if needed
if [[ -f "dot_engine_sim.vcd" ]]; then
  mv -f "dot_engine_sim.vcd" "$VCD_FILE"
fi

echo "[PASS] DOT engine simulation completed successfully."
echo "[INFO] Waveform: $VCD_FILE"
