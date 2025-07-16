import struct
import mpmath
from mpmath import mp

mpmath.mp.dps = 33  # ≈110 bits
mpmath.mp.pretty = True
mpmath.libmp.BACKEND = 'python'

def float_to_8087_bytes(value):
    val = mp.mpf(value)

    sign = 0
    if val < 0:
        sign = 1
        val = -val

    if val == 0:
        return [0x00] * 10

    # Calculate exponent and normalization
    exp = int(mp.floor(mp.log(val, 2)))
    biased_exp = exp + 16383
    norm = val / mp.power(2, exp)

    # Compute mantissa using explicit rounding
    raw = norm * (1 << 63)
    mantissa = int(raw + mp.mpf('0.5'))

    # Correct overflow from rounding to 2.0
    if mantissa >= (1 << 64):
        mantissa >>= 1
        biased_exp += 1

    # Clip to 64-bit value
    mantissa_bytes = mantissa.to_bytes(8, 'little')
    exponent_bytes = struct.pack('<H', (sign << 15) | biased_exp)

    return list(mantissa_bytes + exponent_bytes)

def print_8087_hex(value):
    b = float_to_8087_bytes(value)
    print(f"Value: {value}")
    print("80-bit float (8086 memory order):", " ".join(f"{x:02X}" for x in b))

# === Test ===
print_8087_hex(mp.pi)
print_8087_hex(mp.ln(2))
print_8087_hex(mp.sqrt(2))
