import os
import csv
import re
import subprocess

# Define parameter ranges and values
NUM_THREADS_RANGE = range(4, 17, 2)  # 4 to 16 (even only)
ENABLE_ALU_DSP_OPTIONS = ["true", "false"]
ENABLE_BRAM_REGFILE_OPTIONS = ["true", "false"]
ENABLE_UNIFIED_BARREL_SHIFTER_OPTIONS = ["true", "false"]

SUCCESS_PHRASE = "All user specified timing constraints are met"

def collect_resource_utilization(rundir):
    utilization_report_file = os.path.join(rundir, "post_route_util.rpt")

    pattern = re.compile(
        r"\|\s+RISCV_core_inst\s+\|\s+\S+\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|"
    )

    utilization_data = {
        "Total_LUTs": 0, "Logic_LUTs": 0, "LUTRAMs": 0, "SRLs": 0,
        "FFs": 0, "RAMB36": 0, "RAMB18": 0, "URAM": 0, "DSPs": 0
    }

    if not os.path.isfile(utilization_report_file):
        print(f"Util report file not found: {utilization_report_file}")
        return utilization_data

    # Read the file and search for the matching line
    with open(utilization_report_file, 'r') as file:
        for line in file:
            match = pattern.search(line)
            if match:
                # Populate the dictionary with extracted values
                utilization_data["Total_LUTs"] = int(match.group(1))
                utilization_data["Logic_LUTs"] = int(match.group(2))
                utilization_data["LUTRAMs"] = int(match.group(3))
                utilization_data["SRLs"] = int(match.group(4))
                utilization_data["FFs"] = int(match.group(5))
                utilization_data["RAMB36"] = int(match.group(6))
                utilization_data["RAMB18"] = int(match.group(7))
                utilization_data["URAM"] = int(match.group(8))
                utilization_data["DSPs"] = int(match.group(9))
                break  # Stop after finding the relevant line

    print("RISCV Core Utilization Data:", utilization_data)
    return utilization_data

def collect_power_data(rundir):
    power_report_file = os.path.join(rundir, "post_route_power.rpt")

    pattern = re.compile(
        r"\|\s+RISCV_core_inst\s+\|\s+([\d.]+)\s+\|"
    )

    power_data = {
            "Power (W)" : 0
    }

    if not os.path.isfile(power_report_file):
        return power_data

    with open(power_report_file, 'r') as file:
        for line in file:
            match = pattern.search(line)
            if match:
                # Populate the dictionary with extracted values
                power_data["Power (W)"] = float(match.group(1))
                break  # Stop after finding the relevant line

    print("RISCV Core Power Data:", power_data)
    return power_data
    
def collect_timing_data(rundir):
    timing_report_file = os.path.join(rundir, "post_route_timing_summary.rpt")

    pattern = re.compile(
        r"\s+clkout0\s+\{[0-9.]+\s+[0-9.]+\}\s+[0-9.]+\s+([0-9.]+)"
    )

    best_freq = {
            "Freq (MHz)" : 0
    }

    if not os.path.isfile(timing_report_file):
        return timing_data

    with open(timing_report_file, 'r') as file:
        for line in file:
            match = pattern.search(line)
            if match:
                # Populate the dictionary with extracted values
                best_freq["Freq (MHz)"] = float(match.group(1))
                break  # Stop after finding the relevant line

    print("RISCV Core Best Freq:", best_freq)
    return best_freq

def save_to_csv(data, filename="collected_data.csv"):
    headers = [
        "NUM_THREADS", "PIPE_STAGES", "ENABLE_DSP_ALU", "ENABLE_BRAM_RF",
        "ENABLE_UNIFIED_BARREL_SHIFTER", "BEST_FREQ", 
        "Total_LUTs", "Logic_LUTs", "LUTRAMs", "SRLs", "FFs", 
        "RAMB36", "RAMB18", "URAM", "DSPs", "Power"
    ]
    
    with open(filename, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=headers)
        writer.writeheader()
        writer.writerows(data)

def main():
    collected_data = []

    for num_threads in NUM_THREADS_RANGE:
        for pipe_stages in range(4, num_threads + 1, 2):  # pipe_stages <= num_threads
            for enable_dsp_alu in ENABLE_ALU_DSP_OPTIONS:
                for enable_bram_rf in ENABLE_BRAM_REGFILE_OPTIONS:
                    for enable_unified_barrel_shifter in ENABLE_UNIFIED_BARREL_SHIFTER_OPTIONS:
        
                        rundir_prefix = "rundir"
                        rundir = f"{rundir_prefix}_nt{num_threads}_ps{pipe_stages}_dspalu{enable_dsp_alu}_bramrf{enable_bram_rf}_barrelshifter{enable_unified_barrel_shifter}"

                        if os.path.isdir(rundir):
                            util_data = collect_resource_utilization(rundir)
                            power_data = collect_power_data(rundir)
                            timing_data = collect_timing_data(rundir)
            
                            entry = {
                                "NUM_THREADS": num_threads,
                                "PIPE_STAGES": pipe_stages,
                                "ENABLE_DSP_ALU": enable_dsp_alu,
                                "ENABLE_BRAM_RF": enable_bram_rf,
                                "ENABLE_UNIFIED_BARREL_SHIFTER": enable_unified_barrel_shifter,
                                "BEST_FREQ": timing_data["Freq (MHz)"],
                                "Total_LUTs":util_data["Total_LUTs"],
                                "Logic_LUTs":util_data["Logic_LUTs"],
                                "LUTRAMs":util_data["LUTRAMs"],
                                "SRLs":util_data["SRLs"],
                                "FFs":util_data["FFs"],
                                "RAMB36":util_data["RAMB36"],
                                "RAMB18":util_data["RAMB18"],
                                "URAM":util_data["URAM"],
                                "DSPs":util_data["DSPs"],
                                "Power": power_data["Power (W)"]
                            }
                            collected_data.append(entry)
    
    save_to_csv(collected_data)

if __name__ == "__main__":
    main()

