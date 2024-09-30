import csv

# Input CSV file and output SystemVerilog header (.svh) file
input_csv = 'mmcm_parameters.csv'
output_svh = 'mmcm_lookup_params.svh'

# Open the CSV file and the output SVH file
with open(input_csv, 'r') as csv_file, open(output_svh, 'w') as svh_file:
    # Initialize CSV reader
    reader = csv.DictReader(csv_file)

    # Start writing to the .svh file
    svh_file.write('// Lookup table generated from CSV\n')
    svh_file.write('`ifndef MMCM_LOOKUP_PARAMS_SVH\n')
    svh_file.write('`define MMCM_LOOKUP_PARAMS_SVH\n\n')

    # Collect all rows into memory to determine the array size
    rows = list(reader)
    array_size = len(rows)

    # Write the localparam arrays with explicit sizes
    svh_file.write(f'localparam int desired_freqs[{array_size}] = {{\n')
    freq_list = [row['Desired Frequency'] for row in rows]
    svh_file.write(', '.join(freq_list))
    svh_file.write('};\n\n')

    svh_file.write(f'localparam int D_values[{array_size}] = {{\n')
    D_list = [row['D'] for row in rows]
    svh_file.write(', '.join(D_list))
    svh_file.write('};\n\n')

    svh_file.write(f'localparam real M_values[{array_size}] = {{\n')
    M_list = [row['M'] for row in rows]
    svh_file.write(', '.join(M_list))
    svh_file.write('};\n\n')

    svh_file.write(f'localparam real O_values[{array_size}] = {{\n')
    O_list = [row['O'] for row in rows]
    svh_file.write(', '.join(O_list))
    svh_file.write('};\n\n')

    # Close the define guard
    svh_file.write('`endif // MMCM_LOOKUP_PARAMS_SVH\n')

print(f'Generated SystemVerilog header file: {output_svh}')

