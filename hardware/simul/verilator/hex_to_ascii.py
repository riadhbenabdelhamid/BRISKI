def hex_to_ascii(hex_str):
    """Converts a hexadecimal string to its ASCII equivalent."""
    # Remove '0x' prefix if present
    if hex_str.startswith('0x'):
        hex_str = hex_str[2:]
    
    # Ensure the hex string is even length for proper conversion
    if len(hex_str) % 2 != 0:
        hex_str = '0' + hex_str
    
    # Convert hex to bytes
    bytes_data = bytes.fromhex(hex_str)
    
    # Convert bytes to ASCII, ignoring non-printable characters
    ascii_str = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in bytes_data)
    
    return ascii_str

def process_file(input_file):
    """Processes the memory dump file and converts data to ASCII."""
    ascii_output = []
    
    with open(input_file, 'r') as file:
        for line in file:
            # Skip non-memory lines
            if not line.startswith('memory'):
                continue
            
            # Split the line to extract the hexadecimal value
            parts = line.split(':')
            if len(parts) != 2:
                continue
            
            hex_value = parts[1].strip()
            ascii_value = hex_to_ascii(hex_value)
            ascii_output.append(ascii_value)
    
    return ''.join(ascii_output)

# Replace 'memory_dump.txt' with the path to your file
input_file = 'rtl_memory.txt'
ascii_result = process_file(input_file)
print(ascii_result)

