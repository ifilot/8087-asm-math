import re

# List of 8087 instructions
FPU_INSTRUCTIONS = {
    "fadd", "fsub", "fsubr", "fmul", "fdiv", "fdivr", "fchs", "fabs", "fsqrt", "frndint", "fscale",
    "fptan", "fpatan", "fyl2x", "fyl2xp1", "f2xm1", "fcom", "fcomp",
    "fcompp", "fld", "fst", "fstp", "fxch", "fninit", "finit", "fclex", "fnclex", "fwait", "fincstp",
    "fdecstp", "ffree", "fnstsw", "fstsw", "fnstcw", "fldcw", "fstcw", "fstenv", "fldenv", "fsave",
    "frstor", "fnop", "fist", "fldl2t", "fmulp", "faddp", "fdivp", "fyl2x", "fsubp", "fld1", "fdivrp",
    "fistp", "fild"
}

FPU_MEM_WRITE_INSTRUCTIONS = {
    "fst", "fstp", "fstenv", "fsave", "fstcw", "fstsw", "fistp"
}

def preprocess_8087(filename_in, filename_out):
    with open(filename_in, 'r') as f_in, open(filename_out, 'w') as f_out:
        for line in f_in:
            stripped = line.lstrip()
            if not stripped or stripped.startswith(';'):
                f_out.write(line)
                continue

            # Match the instruction at the start
            match = re.match(r'^([a-zA-Z12]+)', stripped)
            if match:
                instr = match.group(1).lower()

                if instr in FPU_INSTRUCTIONS and instr != "fwait":
                    f_out.write("    fwait\n")  # prepend

                    # Write instruction
                    f_out.write(line)

                    # Append fwait if instruction writes to memory
                    if instr in FPU_MEM_WRITE_INSTRUCTIONS:
                        f_out.write("    fwait\n")
                    continue

            f_out.write(line)  # default

# Example usage
if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python fpu_preprocessor.py <input.spp> <output.asm>")
    else:
        preprocess_8087(sys.argv[1], sys.argv[2])