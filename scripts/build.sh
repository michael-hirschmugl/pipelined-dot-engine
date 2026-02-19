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

# Library workdirs
DOT_WORKDIR="$SIM_DIR/dot_core"
MAC_WORKDIR="$SIM_DIR/mac_core"
TB_WORKDIR="$SIM_DIR/tb"

# ------------------------------------------------------------
# Settings
# ------------------------------------------------------------
STD="08"
TOP="tb_dot_engine"
STOP_TIME="${STOP:-500ns}"
VCD_FILE="$SIM_DIR/dot_engine_sim.vcd"

# Sources (ordered)
DOT_PKG_SRC="$RTL_DIR/dot_types_pkg.vhd"
DOT_DUT_SRC="$RTL_DIR/dot_engine.vhd"
MAC_SRC="$EXT_DIR/rtl/mac.vhd"
TB_SRC="$TB_DIR/tb_dot_engine.vhd"

# ------------------------------------------------------------
# Prepare simulation directory
# ------------------------------------------------------------
mkdir -p "$DOT_WORKDIR" "$MAC_WORKDIR" "$TB_WORKDIR"
rm -f "$DOT_WORKDIR"/work-obj*.cf
rm -f "$MAC_WORKDIR"/work-obj*.cf
rm -f "$TB_WORKDIR"/work-obj*.cf
rm -f "$SIM_DIR/$TOP" "$VCD_FILE"

echo "[INFO] Simulation root: $SIM_DIR"

# ------------------------------------------------------------
# Analyze
# ------------------------------------------------------------
echo "[INFO] Analyzing mac_core (external MAC)..."
ghdl -a --std="$STD" --work=mac_core --workdir="$MAC_WORKDIR" "$MAC_SRC"

echo "[INFO] Analyzing dot_core (package + dut)..."
ghdl -a --std="$STD" --work=dot_core --workdir="$DOT_WORKDIR" "$DOT_PKG_SRC"
ghdl -a --std="$STD" --work=dot_core --workdir="$DOT_WORKDIR" -P"$MAC_WORKDIR" "$DOT_DUT_SRC"

echo "[INFO] Analyzing tb..."
ghdl -a --std="$STD" --work=tb --workdir="$TB_WORKDIR" -P"$DOT_WORKDIR" -P"$MAC_WORKDIR" "$TB_SRC"


# ------------------------------------------------------------
# Elaborate (note the -P paths so ghdl finds other libraries)
# ------------------------------------------------------------
echo "[INFO] Elaborating top-level: $TOP"
ghdl -e --std="$STD" \
  --work=tb --workdir="$TB_WORKDIR" \
  -P"$DOT_WORKDIR" -P"$MAC_WORKDIR" \
  "$TOP"

# ------------------------------------------------------------
# Run simulation
# ------------------------------------------------------------
echo "[INFO] Running simulation..."
ghdl -r --std="$STD" \
  --work=tb --workdir="$TB_WORKDIR" \
  -P"$DOT_WORKDIR" -P"$MAC_WORKDIR" \
  "$TOP" \
  --stop-time="$STOP_TIME" \
  --vcd="$VCD_FILE"

echo "[PASS] DOT engine simulation completed successfully."
echo "[INFO] Waveform: $VCD_FILE"
