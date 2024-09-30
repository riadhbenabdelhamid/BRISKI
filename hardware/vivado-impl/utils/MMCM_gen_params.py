import itertools
import csv  

# Constants
input_frequency = 125  # MHz
vco_range = (800, 1600)  # MHz
D_range = range(1, 107)  # D can range from 1 to 106
M_range = [i/8 for i in range(16, 1025)]  # M can range from 2.0 to 128.0 with 0.125 increments
O_range = [1] + [i/8 for i in range(16, 1025)]  # O can range from 1, 2.0 to 128.0 with 0.125 increments

# Function to compute the parameters for a given desired frequency
def compute_mmcm_params(desired_frequencies):
    results = []

    for desired_freq in desired_frequencies:
        found = False
        # Iterate over all combinations of D, M, and O
        for D, M, O in itertools.product(D_range, M_range, O_range):
            vco_frequency = input_frequency * (M / D)
            if vco_range[0] <= vco_frequency <= vco_range[1]:
                real_freq = vco_frequency / O
                # Check if the real frequency matches the desired frequency
                #if abs(real_freq - desired_freq) < 126e-4:  # Allow a small tolerance
                if abs(real_freq - desired_freq) < 250e-3:  # 
                    results.append({
                        'Input Frequency': input_frequency,
                        'Desired Frequency': desired_freq,
                        'Real Frequency': real_freq,
                        'D': D,
                        'M': M,
                        'O': O
                    })
                    found = True
                    break  # Found a valid combination, move to the next desired frequency
        #if not found:
        #    results.append({
        #        'Desired Frequency': desired_freq,
        #        'Error': 'No valid D, M, O combination found within VCO range'
        #    })
        if not found:
            results.append({
                'Input Frequency': input_frequency,
                'Desired Frequency': desired_freq,
                'Real Frequency': 'N/A',
                'D': 'N/A',
                'M': 'N/A',
                'O': 'N/A'
            })
    return results

# Example usage
#desired_frequencies = [630, 625, 620, 615, 610, 737]  # MMCM desired generated frequencies  
#result = compute_mmcm_params(desired_frequencies) #

# Generate desired frequencies from 100 MHz to 737 MHz with 1 MHz increments
desired_frequencies = list(range(100, 738))  # [100, 101, ..., 737]
#desired_frequencies = list(range(760, 770)) 
#desired_frequencies = list(range(100, 102)) 

# Compute the parameters for each frequency
result = compute_mmcm_params(desired_frequencies)


        # Write results to a CSV file
csv_filename = 'mmcm_parameters.csv'
with open(csv_filename, mode='w', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=['Input Frequency', 'Desired Frequency', 'Real Frequency', 'D', 'M', 'O'])
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
              f"D: {entry['D']}, M: {entry['M']}, O: {entry['O']}")

