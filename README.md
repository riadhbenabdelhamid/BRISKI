# BRISKI

### *Barrel RISC‑V for Kilo‑core Implementations*

A tiny, blazing‑fast, fully‑parameterizable RISC‑V barrel processor for building **many‑core overlays** on FPGAs.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![ISA: RV32I (+Zalrsc)](https://img.shields.io/badge/ISA-RV32I%20%28%2BZalrsc%29-8A2BE2.svg)](#-instruction-set)
[![HDL: SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-orange.svg)](hardware/rtl)
[![Sim: Verilator](https://img.shields.io/badge/Sim-Verilator-green.svg)](hardware/simul/verilator)
[![FPGA: 7‑Series · UltraScale+ · Versal](https://img.shields.io/badge/FPGA-7--Series%20%C2%B7%20UltraScale%2B%20%C2%B7%20Versal-ffce00.svg)](#-fpga-implementation)

BRISKI is a compact RISC‑V **barrel processor** that emphasizes throughput and compute density, so you can pack **thousands of cores** onto a single FPGA without sacrificing clock speed. In its 16‑stage / 16‑thread configuration it runs at the **BlockRAM speed limit — 737 MHz** on a VU9P (VCU118, speed grade ‑2) while using only **~650 LUTs per core**. On newer silicon it goes further still: **850 MHz on an AMD V80** and **1 GHz on some Versal FPGAs (speed grade ‑3)** with around **~700 LUTs per core**.

> 🌋 **See it at scale:** the [**SPARKLE**](#-related-projects) overlay packs **1,024 BRISKI cores / 16,384 hardware threads** on a single datacenter FPGA for **~400 RISC‑V GIPS** — and the SPARKLE update in [**"Design Space Exploration of Fast RISC‑V Processors for Scalable Kilo‑Core FPGA Systems"**](#-publications) boosts the 1,024‑core clock from **400 MHz to 500 MHz**. The [**Fractaski**](https://github.com/riadhbenabdelhamid/Fractaski) demo runs real‑time fractals on a 64‑core BRISKI grid driving VGA on a Nexys‑A7.

---

## ✨ Highlights

- 🪶 **Tiny** — ~650 LUTs per core; optionally packs the ALU into a single DSP block and the register file / PC store into BRAM to shrink the LUT footprint even further.
- ⚡ **Fast** — deep, fully‑pipelined datapath that closes timing at BlockRAM Fmax (737 MHz on UltraScale+) and achieves up to ~850 MHz on Versal V80 speed grade ‑2 and 1 GHz on Versal V80 with speed grade ‑3 — see [publication #5](#-publications).
- 🧵 **Hazard‑free by design** — barrel (interleaved‑multithreading) execution means **no forwarding, no stalls, no branch prediction, no flushes**. Less logic, higher Fmax.
- 🎛️ **Fully parameterizable** — pick **4–16 pipeline stages** and **4–16 hardware threads** at elaboration time; the pipeline auto‑balances itself for the chosen depth.
- 🧱 **Many‑core ready** — a reference top‑level wraps the core with a memory map for **private BRAM**, **shared URAM**, and **MMIO sync** (row arbiter + hardware barriers) so cores compose into grids.
- ✅ **Verified** — Verilator simulation self‑checks against a C++ golden model, with an exhaustive parameter sweep across every test.
- 🛠️ **Push‑button FPGA flow** — one `make` target takes you from C/assembly to a placed‑and‑routed bitstream on several boards (Nexys A7, Nexys Video, VCU118, V80).
- 📖 **Open** — Apache‑2.0 licensed and backed by peer‑reviewed publications.

---

## 🧠 Why a barrel processor?

A barrel processor issues an instruction from a **different hardware thread (hart) every cycle**, round‑robin. As long as `NUM_THREADS ≥ NUM_PIPE_STAGES`, each thread has **at most one instruction in flight** — so by the time a thread comes around again, its previous instruction has fully retired.

```
            pipeline stage:  F    D    E    M    W
   cycle 0                  T0
   cycle 1                  T1   T0
   cycle 2                  T2   T1   T0
   cycle 3                  T3   T2   T1   T0
   cycle 4                  T4   T3   T2   T1   T0     ← pipeline full
   cycle 5                  T5   T4   T3   T2   T1
    ...                     every cycle, a new thread enters; one retires
```

That single design choice removes the most expensive parts of a conventional CPU:

| Conventional in‑order core | BRISKI barrel core |
| --- | --- |
| Forwarding / bypass network | ❌ not needed |
| Hazard detection & interlocks | ❌ not needed |
| Branch predictor + flush logic | ❌ not needed |
| Pipeline limited by critical path | ✅ pipeline as deep as you like → higher Fmax |

The trade‑off is latency vs. throughput: a single thread retires one instruction every `NUM_PIPE_STAGES` cycles, but the core sustains **1 instruction/cycle aggregate** and gives you `NUM_THREADS` independent harts for free. This is ideal for **throughput‑oriented and embarrassingly‑parallel** workloads — exactly what many‑core overlays are built for.

---

## 🚀 Quick start

### Prerequisites

| Tool | Used for | Notes |
| --- | --- | --- |
| [`riscv64-unknown-elf-gcc`](https://github.com/riscv-collab/riscv-gnu-toolchain) | Building programs (`rv32ia` / `ilp32`) | Required for every flow (it generates the program image). |
| [Verilator](https://www.veripool.org/verilator/) | RTL simulation | Fast, free, open‑source. |
| `g++`, `python3`, `make` | Golden model + scripts | Standard toolchain. |
| AMD/Xilinx **Vivado** | FPGA bitstreams | Only needed for the hardware flow. |

### Run a self‑checking simulation in one command

```bash
cd hardware/simul/verilator

# Build the program, simulate the RTL, and diff it against the C++ golden model.
make check_all  HEX_PROG=test_add_sub  NUM_THREADS=10  NUM_PIPE_STAGES=6
```

You should see the RTL register‑file and memory dumps match the reference model (`OK: ... identical.`). A VCD waveform (`waveform.vcd`) is produced for inspection in GTKWave/Surfer.

Try the C example (a per‑thread bubble sort) the same way:

```bash
make check_all_c  HEX_PROG=main  NUM_THREADS=16  NUM_PIPE_STAGES=16
```

Want to stress every configuration? `check_all.py` sweeps **all** pipeline depths × thread counts × feature flags across the whole assembly test suite:

```bash
python3 check_all.py
```

---

## 🗂️ Repository layout

```
BRISKI/
├── hardware/
│   ├── rtl/                  # SystemVerilog source for the core and building blocks
│   │   ├── RISCV_core.sv             # The parameterizable barrel pipeline (heart of BRISKI)
│   │   ├── RISCV_core_top.sv         # Core + unified BRAM + memory-map decoder + MMIO
│   │   ├── RISCV_core_top_extended.sv# Top with the extended MMIO/barrier interface
│   │   ├── alu.sv / alu_dsp.sv       # LUT-based and DSP-packed ALU variants
│   │   ├── regfile_vec.sv            # Per-thread register file (BRAM or LUTRAM)
│   │   ├── reservation_set.sv        # LR/SC reservation set (Zalrsc)
│   │   ├── MMCM_clock_gen.sv         # Family-aware clock generation
│   │   └── ...                       # decoder, control, branch logic, muxes, pipe regs
│   ├── simul/
│   │   ├── verilator/        # Verilator testbench + C++ golden model + sweep script
│   │   └── Makefile          # Vivado xsim flow (alternative simulator)
│   └── vivado-impl/
│       ├── Makefile          # One-shot synth→opt→place→route→bitstream flow
│       ├── compile-scripts/  # Per-stage Vivado Tcl scripts
│       ├── usr-constraints/  # Board XDC pinouts (Nexys A7/Video, VCU118, V80)
│       ├── utils/            # MMCM parameter tables per FPGA family
│       └── bitstream-utils/  # MMI + updatemem flow to reprogram BRAM without re-synthesis
└── software/
    ├── assembly/             # RV32I unit tests (add/sub, branches, loads, shifts, ...)
    ├── C/                    # C examples incl. the SPARKLE mandelbrot template
    ├── hexgen.py             # ELF-dump → BRAM init (.inst) converter
    └── Makefile              # Build programs into core-loadable images
```

---

## 🎛️ Configuration

Every knob is a top‑level parameter (overridable from the Makefiles or `+define+`). Defaults live in [`hardware/rtl/riscv_pkg.sv`](hardware/rtl/riscv_pkg.sv).

| Parameter | Values | Default | What it does |
| --- | --- | --- | --- |
| `NUM_PIPE_STAGES` | `4`–`16` | `16` | Physical pipeline depth. Deeper ⇒ higher Fmax. The stage budget is auto‑distributed across F/D/E/M/WB. |
| `NUM_THREADS` | `4`–`16` (≥ `NUM_PIPE_STAGES`) | `16` | Number of hardware threads (harts). Must be ≥ pipeline depth for hazard‑free operation. |
| `ENABLE_ALU_DSP` | `true`/`false` | `false` | Pack ADD/SUB/AND/OR/XOR into one DSP block (DSP58 / DSP48E2 / DSP48E1) to cut LUTs. |
| `ENABLE_BRAM_REGFILE` | `true`/`false` | `false` | Place the per‑thread register files in BlockRAM (`true`) or distributed LUTRAM (`false`). |
| `ENABLE_UNIFIED_BARREL_SHIFTER` | `true`/`false` | `true` | Use one fixed‑direction logical barrel shifter (+ wrap logic) for SLL/SRL/SRA. |
| `ENABLE_LUTRAM_PCMEM` | `true`/`false` | `true` | Store per‑thread PCs in distributed RAM (`true`) or flip‑flops (`false`). |
| `ENABLE_FETCH_ADDR_PAD` | `true`/`false` | `false` | Add a prefetch stage that registers the instruction‑ROM address (helps BRAM timing). |
| `ENABLE_ZALRSC` | `true`/`false` | `false` | Enable the **Zalrsc** atomics extension (`LR.W` / `SC.W`) with a per‑hart reservation set. |
| `FPGA_FAMILY` | `7SERIES` · `ULTRASCALE` · `ULTRASCALEPLUS` · `VERSAL` | — | Selects DSP primitive (DSP48E1 / DSP48E2 / DSP58) and MMCM parameters. |

> 💡 **Rule of thumb:** keep `NUM_THREADS == NUM_PIPE_STAGES` for the best throughput/area balance. Add threads beyond the pipeline depth only if your software needs more harts.

---

## 📐 Instruction set

BRISKI implements the **RV32I** base integer ISA, plus:

- **Zalrsc** (optional): load‑reserved / store‑conditional (`lr.w` / `sc.w`) for lock‑free synchronization, gated by `ENABLE_ZALRSC`.
- **`mhartid` CSR**: each hart reads its own ID via `csrr`, used to index per‑thread data and barriers.

Multiplication/division (M), floating point (F/D) and compressed (C) are intentionally **not** in hardware — programs use software routines (see the fixed‑point `soft_mul` in the mandelbrot template), keeping each core lean for high core counts.

---

## 🗺️ Core interface & memory map

BRISKI deliberately separates the **core** from the **system around it** — which is what keeps the core tiny and lets you integrate it however you want.

**The core (`RISCV_core`) is memory‑map agnostic.** It exposes two simple synchronous ports and performs **no address decoding** of its own:

| Core port | Signals | Notes |
| --- | --- | --- |
| Instruction fetch | `o_ROM_addr[9:0]` → `i_ROM_instruction[31:0]` | Word‑addressed; a 1024‑word (4 KB) instruction space. |
| Data load/store | `o_dmem_addr[13:0]`, `o_dmem_write_data[31:0]`, `o_dmem_write_enable[3:0]`, `i_dmem_read_data[31:0]` | Flat 32‑bit port with per‑byte write strobes (`SB`/`SH`/`SW`). |

(Plus debug/trace outputs — retired instruction, register‑file write, thread index — used by the verification model.) Wrap this contract around any memory system you like: a single BlockRAM, a bus, a crossbar, or your own peripherals.

**The memory map below belongs to the reference integration** (`RISCV_core_top` / `RISCV_core_top_extended`) — *not* to the core. The wrapper is the worked example of how to drop BRISKI into a (many‑core) system, and the one the SPARKLE overlay uses: it backs both ports with a single dual‑port BlockRAM (1024 × 32‑bit, unified instructions + data) and adds a `memory_map_decoder` that routes data accesses — by their top address bits — into three regions so cores can compute locally, share data, and synchronize:

| Byte address | Region | Description |
| --- | --- | --- |
| `0x0000`–`0x3FFF` | **BRAM** | Private, per‑core local memory (instructions + data). |
| `0x4000`–`0x7FFF` | **URAM** | Shared memory (per row of cores), word‑addressable. |
| `0x8000`–`0xBFFF` | **MMIO** | Inter‑core sync: row‑arbiter request/grant/lock and hardware barriers. |

See [`software/C/sparkle-template-mandelbrot.c`](software/C/sparkle-template-mandelbrot.c) for the canonical example of using all three regions in a many‑core program.

---

## 🚦 Hardware barriers (extended top‑level)

The two reference top‑levels differ in how a core's threads (harts) synchronize:

- **`RISCV_core_top`** uses the base MMIO block (`memory_mapped_interface`): the shared‑memory arbiter handshake (`req` / `grant` / `locked`) plus a `uram_emptied` flag. Barriers among a core's harts are left to **software** (e.g. an atomic counter and a spin loop), costing several memory accesses per hart.
- **`RISCV_core_top_extended`** keeps all of that and adds a **hardware barrier** (`memory_mapped_interface_extended`): a 1‑bit‑per‑hart arrival register and a single combined‑status register (it also widens the MMIO read port to 32 bits to return the whole vector in one load). A core's threads can then rendezvous in roughly **one write + one spinning read** each.

**How it works** — a *sense‑reversing* barrier across the harts of one core:

1. Each hart writes its current *sense* bit to its own slot (`REG_HART_BASE_ADDR + hart_id`, starting at byte `0x8014`).
2. All harts spin‑read the combined‑status register (`0x8054`), which exposes every hart's arrival bit at once.
3. Once all have arrived, the read returns the all‑arrived pattern (`0xFFFF` for 16 harts) and releases the core together; the sense then flips so back‑to‑back barriers can't race.

Publishing arrival in one register and testing it with a single load + compare makes the release effectively O(1) — far cheaper than the software counter. See `atomic_barrier()` in [`software/C/sparkle-template-mandelbrot.c`](software/C/sparkle-template-mandelbrot.c). Inter‑core / row synchronization still relies on the arbiter + URAM handshake, which both top‑levels provide.

---

## 💻 Software workflow

Programs are compiled to an ELF, dumped, and converted into a `.inst` image that initializes the core's BRAM.

```bash
cd software

# Assembly program → runs/test_add_sub.inst
make hex_gen   PROG=test_add_sub   NUM_THREADS=16

# C program → runs/main.inst
make c_hex_gen CPROG=main          NUM_THREADS=16
```

Build flags target `-march=rv32ia -mabi=ilp32 -ffreestanding -nostdlib`. The same `NUM_THREADS` you simulate/synthesize with is passed to the compiler so per‑thread data layouts line up.

**Included programs**

- `software/assembly/` — focused RV32I unit tests: `test_add_sub`, `test_bitwise`, `test_branches`, `test_immediate_arith`, `test_jal_jalr`, `test_load_store`, `test_lui_auipc`, `test_shift`, `test_slt`.
- `software/C/main.c` — per‑thread bubble sort with an optional atomic barrier (Zalrsc).
- `software/C/sparkle-template-mandelbrot.c` — the many‑core fractal template (shared‑memory streaming + hardware barriers).

---

## 🧷 Memory layout: linker script & startup

A BRISKI program is linked to fit the core's single 4 KB unified BRAM and bootstrapped by a tiny per‑hart startup file.

> **These two files are a reference example, not a fixed contract.** They show *one* working operating configuration — the default 4 KB BRAM split into 1 KB of code + 3 KB of data‑and‑stacks, with one stack per hart. Both are plain text you can edit to suit a different setup: a different memory partition, per‑hart stack size, thread count, custom start address, or extra sections — as long as it still fits the core's address space.

### `sections.lds` — where code, data, and stacks live

The linker script splits the 4 KB BRAM (1024 words, `0x000`–`0xFFF`) into two regions and places the sections into them:

```ld
MEMORY {
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 1024   /* .text (code)        */
  RAM (rwx) : ORIGIN = 0x00000400, LENGTH = 3072   /* .data, .bss, stacks */
}
SECTIONS {
  .text : { *(.text) }            > ROM
  .data : { *(.data) }            > RAM
  .bss  : { *(.bss) *(.bss.*) }   > RAM
  _stack_top = ORIGIN(RAM) + LENGTH(RAM) - 4;   /* top of RAM = highest stack address */
}
```

- **Repartition** code vs. data by editing the two `ORIGIN`/`LENGTH` lines — just keep `ROM + RAM = 4096` and `RAM.ORIGIN = ROM.LENGTH` (the file ships commented‑out `2048/2048` and `1536/2560` examples).
- **`_stack_top`** is exported for the startup code and automatically tracks the top of `RAM`, so resizing `RAM` moves every hart's stack.
- Add your own output sections here if needed. The assembly tests use a slimmer variant (`software/assembly/sections.lds`) with no `.bss`/stack, since they don't run C.

### `crt0.s` — per‑hart stacks and `mhartid` → `main`

Every hart boots at address `0x0` into `_start`, which does two things before calling `main`:

1. **Hands the hart ID to `main`.** `csrr a0, mhartid` reads the hardware thread ID into `a0` — the first‑argument register — so a C `main` can take it directly (e.g. `void main(int hartid)`). Each hart runs the *same* program image but individualizes itself by this ID (per‑thread data, barrier slot, …).
2. **Gives each hart its own stack.** It computes `sp = _stack_top − (mhartid × stack_size)` by left‑shifting `mhartid` and subtracting from `_stack_top`. Since every hart derives a different offset, the `NUM_THREADS` harts get non‑overlapping stacks that grow downward from the top of `RAM`.

It then `call`s `main`.

**To resize the per‑hart stack**, change the left‑shift amount in `crt0.s` (the slice size is set by the `slli` shifts, *not* by the `STACK_SIZE` constant). Keep `NUM_THREADS × stack_size` small enough to fit in `RAM` above `.data`/`.bss`, or neighbouring stacks will collide.

---

## 🔬 Simulation & verification

The Verilator flow ([`hardware/simul/verilator`](hardware/simul/verilator)) is the fastest way to iterate:

| Target | What it does |
| --- | --- |
| `make all` | Verilate, build, and run the RTL simulation (expects a prebuilt `.inst`). |
| `make check_all` | Build an **assembly** program, simulate, and diff RTL vs. the C++ golden model. |
| `make check_all_c` | Same, for a **C** program. |
| `python3 check_all.py` | Sweep every `NUM_PIPE_STAGES` × `NUM_THREADS` × feature‑flag combination across all tests. |

Correctness is established by comparing the RTL's committed register files and memory (`rtl_regfiles.txt`, `rtl_memory.txt`) against an independent C++ ISA model ([`simulation_model/BRISKI_simulator.cpp`](hardware/simul/verilator/simulation_model/BRISKI_simulator.cpp)). A waveform (`waveform.vcd`) is always emitted.

A Vivado **xsim** flow is also available in [`hardware/simul/Makefile`](hardware/simul/Makefile) for simulating the full `RISCV_core_top`/`_extended` with the real BRAM/MMIO.

---

## 🔧 FPGA implementation

The Vivado flow ([`hardware/vivado-impl`](hardware/vivado-impl)) builds a bitstream end‑to‑end (synthesis → opt → placement → physopt → routing → bitstream), with family‑aware clocking via MMCM.

```bash
cd hardware/vivado-impl

# Build for a Nexys A7-100T running test_add_sub
make compile  BOARD=Nexys_a7_100T  HEX_NAME=test_add_sub

# Build for an AMD V80 (Versal) running the mandelbrot template
make compile  BOARD=V80            HEX_NAME=sparkle-template-mandelbrot
```

**Supported boards** (add your own XDC in `usr-constraints/`):

| Board | FPGA part | Family | Speed |
| --- | --- | --- | --- |
| Nexys A7‑100T | `xc7a100tcsg324-1` | 7‑Series | up to 300 MHz |
| Nexys Video | `xc7a200tsbg484-1` | 7‑Series | up to 300 MHz |
| VCU118 | `xcvu9p-flga2104-2L-e` | UltraScale+ | up to 737 MHz |
| V80 | `xcv80-lsva4737-2MHP-e-S` | Versal | up to 850 MHz |
| Versal FPGA (grade ‑3) | `xcvh1782-lsva4737-3HP-e-S` | Versal | ![up to 1 GHz](https://img.shields.io/badge/up%20to%201%20GHz-ff0000) |

**Reprogram without re‑synthesis** — swap the program in an existing bitstream by patching the BRAM contents via `updatemem`/MMI:

```bash
make update_mem  HEX_NAME=test_branches
```

The top‑level RTL is selectable (`TOP_RTL`): `core_dummy_wrapper`/`_versal` for single‑core resource/timing characterization, or `RISCV_core_top`/`_extended` for the full memory‑mapped core.

---

## 📊 Reference results

**Single‑core** — one BRISKI core:

<table>
  <thead>
    <tr><th>Configuration</th><th>FPGA (board, speed grade)</th><th>Fmax</th><th>LUTs/core</th></tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3"><b>16 stages / 16 threads</b></td>
      <td>VU9P (VCU118, ‑2)</td><td><b>737 MHz</b> (BRAM limit)</td><td><b>~650</b></td>
    </tr>
    <tr>
      <td>xcv80 (V80 board, ‑2)</td><td><b>850 MHz</b> (BRAM limit)</td><td><b>~635–874</b></td>
    </tr>
    <tr>
      <td>xcvh1782 (‑3)</td><td><b>1 GHz</b> (BRAM limit)</td><td><b>~695–1172</b></td>
    </tr>
  </tbody>
</table>

**Many‑core** — full overlay:

| Configuration | FPGA (board, speed grade) | Aggregate throughput |
| --- | --- | --- |
| 1,024 cores / 16,384 threads (SPARKLE overlay) | VU9P (VCU118, ‑2) | **500 GIPS** (see [publication #4](#-publications)) |

Numbers are from the publications listed below. LUT/core figures for a given board vary with the chosen parameter configuration (pipeline depth, thread count, and feature flags).

---

## 🔗 Related projects

- 🎆 **[Fractaski](https://github.com/riadhbenabdelhamid/Fractaski)** — a 64‑core BRISKI many‑core demo rendering real‑time fractals to a VGA display on a Nexys‑A7 board.
- 🌌 **SPARKLE** — a 1,024‑core / 16,384‑thread single‑FPGA RISC‑V barrel‑processor overlay built on BRISKI (see publications #2 and #3).

---

## 📚 Publications

If you use BRISKI in your work, please cite:

1. R. B. Abdelhamid and D. Koch, "**BRISKI: A RISC-V barrel processor approach for higher throughput with less resource tax**," *2024 IEEE 17th International Symposium on Embedded Multicore/Many-core Systems-on-Chip (MCSoC)*, Kuala Lumpur, Malaysia, 2024, pp. 532-539, doi: [10.1109/MCSoC64144.2024.00092](https://doi.org/10.1109/MCSoC64144.2024.00092).

2. R. B. Abdelhamid, V. Valek and D. Koch, "**SPARKLE: A 1,024-Core/16,384-Thread Single FPGA Many-Core RISC-V Barrel Processor Overlay**," *2024 IEEE 35th International Conference on Application-specific Systems, Architectures and Processors (ASAP)*, Hong Kong, 2024, pp. 118-119, doi: [10.1109/ASAP61560.2024.00032](https://doi.org/10.1109/ASAP61560.2024.00032).

3. R. B. Abdelhamid, V. Valek and D. Koch, "**SPARKLE: 400 RISC-V GIPS with 1,024 Barrel Processors on a single Datacenter FPGA Card**," *2024 IEEE 17th International Symposium on Embedded Multicore/Many-core Systems-on-Chip (MCSoC)*, Kuala Lumpur, Malaysia, 2024, pp. 524-531, doi: [10.1109/MCSoC64144.2024.00091](https://doi.org/10.1109/MCSoC64144.2024.00091).

4. R. B. Abdelhamid, V. Valek, K. Klein and D. Koch, "**Design Space Exploration of Fast RISC-V Processors for Scalable Kilo-Core FPGA Systems**," *2025 35th International Conference on Field-Programmable Logic and Applications (FPL)*, 2025, pp. 282-290, doi: [10.1109/FPL68686.2025.00046](https://doi.org/10.1109/FPL68686.2025.00046).

5. R. B. Abdelhamid and D. Koch, "**A 1-GHz RISC-V Soft-Core Processor**," *2026 36th International Conference on Field-Programmable Logic and Applications (FPL)*, 2026. **_(Just accepted — to appear.)_**

<details>
<summary>BibTeX</summary>

```bibtex
@inproceedings{abdelhamid2024briski,
  author    = {Abdelhamid, Riadh Ben and Koch, Dirk},
  title     = {{BRISKI}: A {RISC-V} Barrel Processor Approach for Higher Throughput with Less Resource Tax},
  booktitle = {2024 IEEE 17th International Symposium on Embedded Multicore/Many-core Systems-on-Chip (MCSoC)},
  year      = {2024},
  pages     = {532--539},
  doi       = {10.1109/MCSoC64144.2024.00092}
}

@inproceedings{abdelhamid2024sparkleasap,
  author    = {Abdelhamid, Riadh Ben and Valek, Vladislav and Koch, Dirk},
  title     = {{SPARKLE}: A 1,024-Core/16,384-Thread Single {FPGA} Many-Core {RISC-V} Barrel Processor Overlay},
  booktitle = {2024 IEEE 35th International Conference on Application-specific Systems, Architectures and Processors (ASAP)},
  year      = {2024},
  pages     = {118--119},
  doi       = {10.1109/ASAP61560.2024.00032}
}

@inproceedings{abdelhamid2024sparklemcsoc,
  author    = {Abdelhamid, Riadh Ben and Valek, Vladislav and Koch, Dirk},
  title     = {{SPARKLE}: 400 {RISC-V} {GIPS} with 1,024 Barrel Processors on a single Datacenter {FPGA} Card},
  booktitle = {2024 IEEE 17th International Symposium on Embedded Multicore/Many-core Systems-on-Chip (MCSoC)},
  year      = {2024},
  pages     = {524--531},
  doi       = {10.1109/MCSoC64144.2024.00091}
}

@inproceedings{abdelhamid2025dse,
  author    = {Abdelhamid, Riadh Ben and Valek, Vladislav and Klein, Kevin and Koch, Dirk},
  title     = {Design Space Exploration of Fast {RISC-V} Processors for Scalable Kilo-Core {FPGA} Systems},
  booktitle = {2025 35th International Conference on Field-Programmable Logic and Applications (FPL)},
  year      = {2025},
  pages     = {282--290},
  doi       = {10.1109/FPL68686.2025.00046}
}

@inproceedings{abdelhamid2026ghz,
  author    = {Abdelhamid, Riadh Ben and Koch, Dirk},
  title     = {A 1-{GHz} {RISC-V} Soft-Core Processor},
  booktitle = {2026 36th International Conference on Field-Programmable Logic and Applications (FPL)},
  year      = {2026},
  note      = {Just accepted, to appear}
}
```
</details>

---

## 📄 License

BRISKI is released under the [Apache License 2.0](LICENSE).

## 🤝 Contributing

Issues and pull requests are welcome — bug reports, new board constraint files, additional tests, and ISA extensions are all great ways to help. Please run `python3 hardware/simul/verilator/check_all.py` before submitting RTL changes so the parameter sweep stays green.
