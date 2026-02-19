# pipelined-dot-engine

A small, accelerator-style dot-product engine built around a reusable
pipelined MAC core.

The repository contains:

- A VHDL implementation (`vhdl` branch)
- A SystemVerilog implementation (`systemverilog` branch)

The `main` branch contains documentation and the common project
structure.

This project focuses on:

- Clean RTL structure
- Explicit library mapping
- Reproducible simulation builds
- Clear separation of IP core and integration logic

------------------------------------------------------------------------

## Design Overview

The dot engine instantiates two pipelined MAC cores and computes a dot
product over a fixed-length vector (currently `VEC_LEN = 4`).

The MAC core is included as a **Git submodule** under:

    external/pipelined-mac-core

The dot engine is responsible for:

- Loading vector elements
- Driving MAC instances
- Collecting partial sums
- Producing a final accumulated result
- Managing valid/ready handshake

📘 Detailed technical documentation is available here:

**[Dot Engine Technical Reference](docs/dot_engine_technical_reference.md)**

------------------------------------------------------------------------

## Repository Structure

```bash
rtl/        # synthesizable RTL (dot engine + package)
tb/         # testbench
external/   # external dependencies (git submodules)
docs/       # documentation
scripts/    # build helpers
sim/        # simulator output (ignored by git)
```

------------------------------------------------------------------------

## Branches

- `main`  
  Documentation and shared project structure only.

- `vhdl`  
  VHDL-2008 implementation (GHDL flow).

- `systemverilog`  
  SystemVerilog implementation.

------------------------------------------------------------------------

## VHDL Simulation Architecture (Library Mapping)

The VHDL branch uses explicit library separation:

| Library    | Contents                  | Location           |
|------------|---------------------------|-------------------|
| `dot_core` | dot_types_pkg, dot_engine | `sim/dot_core/`   |
| `mac_core` | MAC core (submodule)      | `sim/mac_core/`   |
| `tb`       | testbench                 | `sim/tb/`         |

Generated files:

```bash
sim/
 ├── dot_core/dot_core-obj08.cf
 ├── mac_core/mac_core-obj08.cf
 ├── tb/tb-obj08.cf
 └── dot_engine_sim.vcd
```

------------------------------------------------------------------------

## Quick Start (VHDL branch)

### Prerequisites

- GHDL (VHDL-2008 capable)
- Make

### Run simulation

```bash
make sim
```

Waveform output:

    sim/dot_engine_sim.vcd

### Clean build artifacts

```bash
make clean
```

------------------------------------------------------------------------

## Submodule Handling

After switching to `vhdl` or `systemverilog`:

```bash
git submodule update --init --recursive
```

To fully clean the working tree when switching back to `main`:

```bash
git clean -ffd
```

⚠ This removes all untracked files and directories.

------------------------------------------------------------------------

## License

GPL-2.0-or-later.  
See `LICENSE` file.
