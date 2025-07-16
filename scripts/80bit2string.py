from mpmath import mp

# Set high enough precision
mp.prec = 100

def bytes_to_extended_float(byte_list):
    """Convert a 10-byte (80-bit) float to decimal (mpf)"""
    if len(byte_list) != 10:
        raise ValueError("Expected 10 bytes for 80-bit float")

    # Convert to little-endian integer values
    low = int.from_bytes(byte_list[:8], 'little')
    high = int.from_bytes(byte_list[8:], 'little')  # exponent and sign

    # Extract exponent (15 bits) and sign (bit 15)
    exponent_raw = high & 0x7FFF
    sign = (high >> 15) & 0x1

    # Handle special cases
    if exponent_raw == 0 and low == 0:
        return mp.mpf(0.0) * (-1 if sign else 1)

    exponent = exponent_raw - 16383  # unbiased exponent

    # Extract mantissa
    int_bit = 1  # In 80-bit, the integer bit is explicit and always 1 for normals
    int_bit = (low >> 63) & 1
    frac_bits = low & ((1 << 63) - 1)  # mask off integer bit
    mantissa = mp.mpf(frac_bits) / mp.power(2, 63)
    value = mp.power(2, exponent) * (int_bit + mantissa)

    if sign:
        value = -value

    return value

# Example input: 80-bit float bytes from memory (little endian)
# ln(2) stored in x87: 0080 DA04 4A25 B897 FE3F
#raw_bytes = bytes.fromhex("0080DA044A25B897FE3F")
raw_bytes = bytes.fromhex("0061BD486AD429940840")

# Convert to decimal
decimal_value = bytes_to_extended_float(list(raw_bytes))
print("Decimal value:", decimal_value)
