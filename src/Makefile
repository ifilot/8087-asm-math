# Find all ex??.asm files and convert to .com targets
ASM_FILES = $(wildcard ex??.asm)
PROGRAMS = $(ASM_FILES:.asm=.com)

# Default target
all: $(PROGRAMS)

# Tools and flags
NASM = nasm
NASMFLAGS = -w+error
PREPROCESSOR = python3 ../scripts/preprocessor.py

# Preprocessing: convert all .spp files to .asm in floatroutines/
FLOAT_SPP = $(wildcard floatroutines/*.spp)
FLOAT_ASM = $(FLOAT_SPP:.spp=.asm)

# Rule to generate .asm files from .spp using preprocessor.py
floatroutines/%.asm: floatroutines/%.spp ../scripts/preprocessor.py
	$(PREPROCESSOR) $< $@

# Make all floatroutines .asm files before building any .com
# Each .com file depends on all of them
COMMON_SRC = $(FLOAT_ASM)

# Pattern rule for building .com from .asm
%.com: %.asm $(COMMON_SRC)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Special case for ex05.com (requires io/io.asm too)
ex05.com: ex05.asm $(COMMON_SRC) io/io.asm
	$(NASM) $(NASMFLAGS) -o $@ ex05.asm

# Run target
run: $(FILE).com
	dosbox-x -conf dosbox-x.conf -exit $(FILE).com

# Optional: clean target
clean:
	rm -f *.com $(FLOAT_ASM)