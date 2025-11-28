#!/usr/bin/env python3
import os
import sys
import subprocess

# Range for sweeping pipeline stages / threads
MIN_VAL = 4
MAX_VAL = 16

# This is a Python boolean; we'll export it to the Makefile as "true"/"false"
ENABLE_ALU_DSP = True

# Make target to build/run
TARGET = "check_all"  # or "check_all_c"

# List every assembly test you want to run. The Makefile expects the *bare name* (e.g., test_add_sub).
# We'll automatically strip any path or extension you might include here.
ASM_TESTLIST = [
    "test_add_sub",
    "test_bitwise",
    "test_branches",
    "test_jal_jalr",
    "test_load_store",
    "test_lui_auipc",
    "test_shift",
    "test_slt",
]

def _bool_to_make(b: bool) -> str:
    """Convert Python bool to the lowercase strings Makefile expects."""
    return "true" if b else "false"

def _bare_name(name: str) -> str:
    """Return the bare test name: drop any directories and file extensions."""
    base = os.path.basename(str(name))
    root, _ = os.path.splitext(base)
    return root

def run_make(hex_prog: str,
             num_threads: int,
             num_pipe_stages: int,
             enable_unified_barrel_shifter: bool,
             enable_fetch_addr_pad: bool,
             enable_zalrsc: bool) -> int:
    """Run `make TARGET` with the given env vars. Return the exit code."""

    env = os.environ.copy()
    env["HEX_PROG"] = _bare_name(hex_prog)               # bare name only
    env["NUM_THREADS"] = str(num_threads)
    env["NUM_PIPE_STAGES"] = str(num_pipe_stages)
    env["ENABLE_UNIFIED_BARREL_SHIFTER"] = _bool_to_make(enable_unified_barrel_shifter)
    env["ENABLE_FETCH_ADDR_PAD"] = _bool_to_make(enable_fetch_addr_pad)
    env["ENABLE_ZALRSC"] = _bool_to_make(enable_zalrsc)
    env["ENABLE_ALU_DSP"] = _bool_to_make(ENABLE_ALU_DSP)

    print(
        "\n=== Running:"
        f" HEX_PROG={env['HEX_PROG']}"
        f" NUM_THREADS={num_threads}"
        f" NUM_PIPE_STAGES={num_pipe_stages}"
        f" UBARREL={env['ENABLE_UNIFIED_BARREL_SHIFTER']}"
        f" FETCH_ADDR_PAD={env['ENABLE_FETCH_ADDR_PAD']}"
        f" ZALRSC={env['ENABLE_ZALRSC']}"
        f" ALU_DSP={env['ENABLE_ALU_DSP']}"
        f" -> make {TARGET} ==="
    )

    try:
        completed = subprocess.run(["make", TARGET], env=env, check=False)
        return completed.returncode
    except FileNotFoundError:
        print("Error: `make` not found on PATH.", file=sys.stderr)
        return 127

def main() -> int:
    """
    Sweep all combinations of:
      - hex_prog ∈ ASM_TESTLIST
      - enable_* flags ∈ {false, true} (exported as strings for Make)
      - num_pipe_stages, num_threads in [MIN_VAL..MAX_VAL] with NUM_THREADS >= NUM_PIPE_STAGES
        NOTE: when ENABLE_FETCH_ADDR_PAD is true, the lower bound becomes 5 instead of 4
    """
    failures = []
    total_runs = 0

    bools = [False, True]

    for hex_prog in ASM_TESTLIST:
        for enable_unified_barrel_shifter in bools:
            for enable_fetch_addr_pad in bools:
                # When FETCH_ADDR_PAD is enabled, start at 5
                min_val = 5 if enable_fetch_addr_pad else MIN_VAL
                for enable_zalrsc in bools:
                    for nps in range(min_val, MAX_VAL + 1):
                        # ensure NUM_THREADS >= NUM_PIPE_STAGES
                        for nt in range(nps, MAX_VAL + 1):
                            rc = run_make(
                                hex_prog=hex_prog,
                                num_threads=nt,
                                num_pipe_stages=nps,
                                enable_unified_barrel_shifter=enable_unified_barrel_shifter,
                                enable_fetch_addr_pad=enable_fetch_addr_pad,
                                enable_zalrsc=enable_zalrsc,
                            )
                            total_runs += 1
                            if rc != 0:
                                failures.append({
                                    "hex_prog": _bare_name(hex_prog),
                                    "num_threads": nt,
                                    "num_pipe_stages": nps,
                                    "enable_unified_barrel_shifter": enable_unified_barrel_shifter,
                                    "enable_fetch_addr_pad": enable_fetch_addr_pad,
                                    "enable_zalrsc": enable_zalrsc,
                                    "exit_code": rc,
                                })
                    

    if failures:
        print(f"\nFailures ({len(failures)}):")
        for f in failures:
            print(
                "  HEX_PROG={hex_prog} NT={num_threads} NPS={num_pipe_stages} "
                " UBARREL={enable_unified_barrel_shifter} "
                " FETCH_ADDR_PAD={enable_fetch_addr_pad} "
                " ZALRSC={enable_zalrsc} -> exit {exit_code}"
                .format(**f)
            )
        print("\n===== Summary =====")
        print(f"Tried {total_runs} runs across all parameter combinations.")
        print("Check failing tests.")
        return 1
    else:
        print("\n===== Summary =====")
        print(f"Tried {total_runs} runs across all parameter combinations.")
        print("All runs succeeded.")
        return 0

if __name__ == "__main__":
    sys.exit(main())
