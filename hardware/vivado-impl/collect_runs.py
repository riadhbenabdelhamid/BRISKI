import os
import subprocess
#import shutil

# Define parameter ranges and values
NUM_THREADS_RANGE = range(4, 17, 2)  # 4 to 16 (even only)
#NUM_PIPE_STAGES_RANGE = range(4, 17, 2)  # 4 to 16 (but less than or equal to NUM_THREADS)
ENABLE_ALU_DSP_OPTIONS = ["true", "false"]
ENABLE_BRAM_REGFILE_OPTIONS = ["true", "false"]
ENABLE_UNIFIED_BARREL_SHIFTER_OPTIONS = ["true", "false"]
FREQ_RANGE = (200, 737)  # Binary search over this range

# Define the phrase to search in the report file
SUCCESS_PHRASE = "All user specified timing constraints are met"

# Function to check if the phrase is in the report file
def check_timing_constraints_met(rundir):
    report_file = os.path.join(rundir, "post_route_timing_summary.rpt")
    if not os.path.isfile(report_file):
        return False
    with open(report_file, 'r') as file:
        for line in file:
            if SUCCESS_PHRASE in line:
                return True
    return False

# Binary search over the frequency
def binary_search_freq(num_threads, pipe_stages, enable_dsp_alu, enable_bram_rf, enable_unified_barrel_shifter, rundir_prefix):
    low, high = FREQ_RANGE
    best_freq = low

    while low <= high:
        mid = (low + high) // 2
        #rundir = f"{rundir_prefix}_freq{mid}_nt{num_threads}_ps{pipe_stages}_dspalu{enable_dsp_alu}_bramrf{enable_bram_rf}_barrelshifter{enable_unified_barrel_shifter}"
        rundir = f"{rundir_prefix}_nt{num_threads}_ps{pipe_stages}_dspalu{enable_dsp_alu}_bramrf{enable_bram_rf}_barrelshifter{enable_unified_barrel_shifter}"
        
        # Prepare the environment for the make command
        env_vars = os.environ.copy()
        env_vars['NUM_THREADS']=str(num_threads)
        env_vars['NUM_PIPE_STAGES']=str(pipe_stages)
        env_vars['ENABLE_ALU_DSP']=str(enable_dsp_alu).lower()
        env_vars['ENABLE_BRAM_REGFILE']=str(enable_bram_rf).lower()
        env_vars['ENABLE_UNIFIED_BARREL_SHIFTER']=str(enable_unified_barrel_shifter).lower()
        env_vars['MMCM_OUT_FREQ_MHZ']=str(mid)
        env_vars['RUN_DIR']=rundir
        
        
        # Create the rundir directory
        #if os.path.exists(rundir):
        #    shutil.rmtree(rundir)
        #os.makedirs(rundir)

        # Run the make command
        #make_command = ['make', 'all']
        make_cmd = ["make", "all"]
        #result = subprocess.run(make_cmd, env=env_vars, shell=True)
        #result = subprocess.run(make_cmd, env=env_vars, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            #result = subprocess.run(make_cmd, shell=True, capture_output=True, text=True)
            result = subprocess.run(make_cmd, env=env_vars, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

            # Print stdout and stderr for debugging
            print(f"Command: {make_cmd}")
            print("Output:", result.stdout)
            print("Error:", result.stderr)

            # Check if the command was successful
            if result.returncode == 0:
                print(f"Success at {mid_freq} MHz for configuration: {make_params}")
                min_freq = mid_freq + 1  # Try higher frequencies
            else:
                print(f"Failure at {mid_freq} MHz for configuration: {make_params}")
                max_freq = mid_freq - 1  # Try lower frequencies

        except subprocess.CalledProcessError as e:
            print(f"Error running command: {e}")
            break

        # Check if timing constraints are met
        if check_timing_constraints_met(rundir):
            best_freq = mid  # Update the best freq
            low = mid + 1  # Try a higher frequency
        else:
            high = mid - 1  # Try a lower frequency

    return best_freq

# Main function to iterate over all parameter combinations and perform binary search
def iterate_combinations():
    for num_threads in NUM_THREADS_RANGE:
        for pipe_stages in range(4, num_threads + 1, 2):  # pipe_stages <= num_threads
            for enable_dsp_alu in ENABLE_ALU_DSP_OPTIONS:
                for enable_bram_rf in ENABLE_BRAM_REGFILE_OPTIONS:
                    for enable_unified_barrel_shifter in ENABLE_UNIFIED_BARREL_SHIFTER_OPTIONS:
                        rundir_prefix = "rundir"
                        best_freq = binary_search_freq(
                            num_threads, pipe_stages, enable_dsp_alu,
                            enable_bram_rf, enable_unified_barrel_shifter,
                            rundir_prefix
                        )
                        if best_freq:
                            print(f"Best frequency for configuration (NUM_THREADS={num_threads}, "
                                  f"NUM_PIPE_STAGES={pipe_stages}, ENABLE_ALU_DSP={enable_dsp_alu}, "
                                  f"ENABLE_BRAM_REGFILE={enable_bram_rf}, "
                                  f"ENABLE_UNIFIED_BARREL_SHIFTER={enable_unified_barrel_shifter}): {best_freq} MHz")
                        else:
                            print(f"No valid frequency found for configuration (NUM_THREADS={num_threads}, "
                                  f"NUM_PIPE_STAGES={pipe_stages}, ENABLE_ALU_DSP={enable_dsp_alu}, "
                                  f"ENABLE_BRAM_REGFILE={enable_bram_rf}, "
                                  f"ENABLE_UNIFIED_BARREL_SHIFTER={enable_unified_barrel_shifter})")

if __name__ == "__main__":
    iterate_combinations()

