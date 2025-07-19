# 8087 Assembly Examples for MS-DOS

This repository provides a curated set of example programs demonstrating how to
use the **Intel 8087 math coprocessor** in conjunction with **8086/8088 assembly
code** under a **real-mode MS-DOS environment**.

## 📌 Purpose

The goal of this project is to serve as a practical reference for:
- Understanding how to perform **floating-point arithmetic** using the 8087
- Learning how the x87 FPU integrates with 8086/8088 instructions
- Demonstrating the use of FPU instructions such as `FLD`, `FST`, `FADD`,
  `F2XM1`, `FSCALE`, `FYL2X`, etc.
- Showing best practices for managing the x87 FPU stack
- Implementing common math operations like `exp(x)` or `pow(a, b)` manually

## 🧠 Assumptions

- The code is designed to run in a **16-bit real mode** environment (e.g.
  MS-DOS)
- You have an **8086 or 8088 CPU** with an **8087 numeric coprocessor**
  installed
- You can assemble and link `.asm` files using tools like NASM.
- You can run the resulting binaries in a **DOSBox**, **DOSBox-X**, or **real
  hardware** (I have tested on an IBM 5150)

## ▶ How to compile and run

```bash
make
make rundosbox-x
```
