import itertools
import csv  

# Constants
input_frequency = 125  # MHz #change as needed (125 MHz : VCU118, 100 MHz : nexys-a7-100, 100 MHz : V80 versal hbm)
vco_range = (800, 1600)  # MHz #change as needed
#vco_range = (600, 1200)  # MHz #change as needed (800--1600 VCU118, 600-1200 nexys-a7-100)
#vco_range = (2160, 4320)  # MHz #change as needed (Alveo V80)

def get_mmcm_ranges(fpga_family: str):
    """
    Return D, M, and O ranges based on FPGA family.
    """

    if fpga_family.upper() == "7SERIES":
        # MMCME2
        D_range = range(1, 107)  # 1–106
        M_range = [i/8 for i in range(16, 513)]  # 2.0–64.0, step 0.125
        F_range = [0]  
        O_range = [1] + [i/8 for i in range(16, 1025)]  # 1, 2.0–128.0

    elif fpga_family.upper() == "ULTRASCALE":
        # MMCME3
        D_range = range(1, 107)  # 1–106
        M_range = [i/8 for i in range(16, 1025)]  # 2.0–128.0
        F_range = [0]  
        O_range = [1] + [i/8 for i in range(16, 1025)]  # 1, 2.0–128.0

    elif fpga_family.upper() == "ULTRASCALEPLUS":
        # MMCME3 / MMCME4
        D_range = range(1, 107)  # D can range from 1 to 106
        M_range = [i/8 for i in range(16, 1025)]  # M can range from 2.0 to 128.0 with 0.125 increments
        F_range = [0]  
        O_range = [1] + [i/8 for i in range(16, 1025)]  # O can range from 1, 2.0 to 128.0 with 0.125 increments
    elif fpga_family.upper() == "VERSAL":
        # MMCME5
        D_range = range(1, 124)  # 1–123
        M_range = range(4, 433)
        F_range = range(64)  
        O_range = range(2,512)

    else:
        raise ValueError(f"Unsupported FPGA family: {fpga_family}")

    return D_range, M_range, F_range, O_range


# Example usage:
fpga_family = "ULTRASCALEPLUS"
#fpga_family = "7SERIES"
#fpga_family = "VERSAL"
D_range, M_range, F_range, O_range = get_mmcm_ranges(fpga_family)


# Function to compute the parameters for a given desired frequency
def compute_mmcm_params(desired_frequencies):
    results = []

    for desired_freq in desired_frequencies:
        best_result = None
        best_vco_freq_diff = float('inf')  # Initialize with a large number
        
        # Iterate over all combinations of D, M, and O
        for D, M, F, O in itertools.product(D_range, M_range, F_range, O_range):
            vco_frequency = input_frequency * ((M+(F/64)) / D)
            
            # Check if VCO frequency is within the allowed range
            if vco_range[0] <= vco_frequency <= vco_range[1]:
                real_freq = vco_frequency / O
                
                # Check if the real frequency matches the desired frequency within tolerance
                if abs(real_freq - desired_freq) < 250e-3:
                    # Compute how close the VCO frequency is to the upper limit of the VCO range
                    vco_freq_diff = vco_range[1] - vco_frequency
                    
                    # If this is the closest VCO frequency to the upper limit, store the result
                    if vco_freq_diff < best_vco_freq_diff:
                        best_vco_freq_diff = vco_freq_diff
                        best_result = {
                            'Input Frequency': input_frequency,
                            'Desired Frequency': desired_freq,
                            'Real Frequency': real_freq,
                            'D': D,
                            'M': M,
                            'F': F,
                            'O': O
                        }
        
        # If a valid combination was found, append the best result, otherwise append 'N/A'
        if best_result:
            results.append(best_result)
        else:
            results.append({
                'Input Frequency': input_frequency,
                'Desired Frequency': desired_freq,
                'Real Frequency': 'N/A',
                'D': 'N/A',
                'M': 'N/A',
                'F': 'N/A',
                'O': 'N/A'
            })
    
    return results
# Example usage
#desired_frequencies = [630, 625, 620, 615, 610, 737]  # MMCM desired generated frequencies  
#result = compute_mmcm_params(desired_frequencies) #

# Generate desired frequencies from 100 MHz to 737 MHz with 1 MHz increments
#desired_frequencies = list(range(500, 501))  # [100, 101, ..., 737]
desired_frequencies = list(range(100, 738))  # [100, 101, ..., 737]
#desired_frequencies = list(range(50, 451))  # [50, 51, ..., 450] (nexys-a7-100)
#desired_frequencies = list(range(700, 850)) # (Alveo V80)
#desired_frequencies = list(range(100, 1001)) # (Versal HBM Speed grade -3)
#desired_frequencies = list(range(100, 102)) 

# Compute the parameters for each frequency
result = compute_mmcm_params(desired_frequencies)


        # Write results to a CSV file
csv_filename = f'mmcm_parameters_{fpga_family}.csv'
with open(csv_filename, mode='w', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=['Input Frequency', 'Desired Frequency', 'Real Frequency', 'D', 'M', 'F', 'O'])
    writer.writeheader()
    for entry in result:
        writer.writerow(entry)

print(f"MMCM parameters have been saved to {csv_filename}.")

# Display results
for entry in result:
    if 'Error' in entry:
        print(f"Desired Frequency: {entry['Desired Frequency']} MHz - {entry['Error']}")
    else:
        print(f"Desired Frequency: {entry['Desired Frequency']} MHz, "
              f"Real Frequency: {entry['Real Frequency']:.3f} MHz, "
              f"D: {entry['D']}, M: {entry['M']}, F: {entry['F']}, O: {entry['O']}")

