#!/usr/bin/env python3

import argparse

def parse_elf_dump(filename):
    sections = {'.text': [], '.data': []}
    current_section = None
    current_address = 0
    section_started = False

    with open(filename, 'r') as file:
        lines = file.readlines()

    for line in lines:
        # Break the loop if an empty line is encountered
        if section_started and not line.strip():
            break
        # Detect the start of sections
        if 'Contents of section .text:' in line:
            last_address = 0
            current_section = '.text'
            current_address = 0
            section_started = True
            first_line = True
            continue
        elif 'Contents of section .data:' in line:
            current_section = '.data'
            last_address = current_address
            current_address = 0 
            section_started = True
            first_line = True
            continue
        elif 'Contents of section' in line:
            current_section = None
            section_started = False
            first_line = False

        if current_section:
            # Extract the address and words from the line
            parts = line.strip().split(" ")
            #print("parts: ", parts)

            if len(parts) > 1:
                addr_str = parts[0].strip()
                # Check if the address part is a valid hexadecimal string
                if addr_str.isalnum():
                #if True:
                    try:
                        addr = int(addr_str, 16)
                        words = parts[1:5]

                        if first_line :
                            current_address = addr
                            first_line = False

                        # Fill the gap from the last address to the current address
                        #while current_address < addr:
                        while last_address != 0 and last_address < addr:
                            sections[current_section].append('00000000')
                            last_address += 4

                        for word in words:
                            # Ensure the word is exactly 8 characters long
                            word = word.strip()
                            if word == '':
                                word = '00000000'
                            elif len(word) < 8:
                                word = word.ljust(8, '0')

                            if all(c in '0123456789abcdefABCDEF' for c in word):
                                sections[current_section].append(word)
                                current_address += 4
                                last_address += 4

                    except ValueError:
                        # break if the address is not valid
                        break

    return sections

def swap_endianness(hex_str):
    """Swap endianness of a 8-character hexadecimal string."""
    # Ensure the input is a valid 8-character hex string
    if len(hex_str) != 8 or not all(c in '0123456789abcdefABCDEF' for c in hex_str):
        print(hex_str)
        raise ValueError("Invalid hexadecimal string")
    
    # Split the hex string into 2-byte chunks, reverse the chunks, and reassemble
    swapped = ''.join(reversed([hex_str[i:i+2] for i in range(0, 8, 2)]))
    return swapped

def write_inst_file(sections, output_filename):
    with open(output_filename, 'w') as file:
        max_lines = 1024
        lines_written = 0

        # Collect all words in a single list
        all_words = []
        for section in ['.text', '.data']:
            all_words.extend(sections[section])

        # Write words to the output file
        for word in all_words:
            if lines_written >= max_lines:
                break
            file.write(swap_endianness(word) + '\n')
            lines_written += 1

        # Fill remaining lines with "00000000"
        while lines_written < max_lines:
            file.write("00000000\n")
            lines_written += 1

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert ELF disassembly to .inst file.")
    parser.add_argument('input_file', help="The input ELF disassembly file.")
    parser.add_argument('output_file', help="The output .inst file.")

    args = parser.parse_args()

    sections = parse_elf_dump(args.input_file)
    write_inst_file(sections, args.output_file)

