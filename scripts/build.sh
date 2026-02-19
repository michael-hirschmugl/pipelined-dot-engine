#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Paths (relative to repo root)
# ------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL_DIR="$ROOT_DIR/rtl"
TB_DIR="$ROOT_DIR/tb"
SIM_DIR="$ROOT_DIR/sim"

# ------------------------------------------------------------
# Design / simulation settings
# ------------------------------------------------------------
STD="08"
TOP="tb_mac"
STOP_TIME="${STOP:-500ns}"
VCD_FILE="$SIM_DIR/mac_sim.vcd"

# Source files
RTL_SRC="$RTL_DIR/mac.vhd"
TB_SRC="$TB_DIR/tb_mac.vhd"

# ------------------------------------------------------------
# Prepare simulation directory
# ------------------------------------------------------------
mkdir -p "$SIM_DIR"
rm -f "$SIM_DIR"/work-obj*.cf
rm -f "$SIM_DIR/$TOP"
rm -f "$VCD_FILE"

echo "[INFO] Simulation directory: $SIM_DIR"

# ------------------------------------------------------------
# Analyze sources (VHDL-2008)
# ------------------------------------------------------------
echo "[INFO] Analyzing RTL..."
ghdl -a --std="$STD" --workdir="$SIM_DIR" "$RTL_SRC"

echo "[INFO] Analyzing testbench..."
ghdl -a --std="$STD" --workdir="$SIM_DIR" "$TB_SRC"

# ------------------------------------------------------------
# Elaborate
# ------------------------------------------------------------
echo "[INFO] Elaborating top-level: $TOP"
ghdl -e --std="$STD" --workdir="$SIM_DIR" "$TOP"

# ------------------------------------------------------------
# Run simulation
# ------------------------------------------------------------
echo "[INFO] Running simulation..."
ghdl -r --std="$STD" --workdir="$SIM_DIR" "$TOP" \
  --stop-time="$STOP_TIME" \
  --vcd="$VCD_FILE"

echo "[PASS] MAC simulation completed successfully."
echo "[INFO] Waveform: $VCD_FILE"
