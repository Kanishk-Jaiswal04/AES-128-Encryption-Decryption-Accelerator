# AES-128 Encryption/Decryption Accelerator

A small AES-128 accelerator written in SystemVerilog with a minimal AXI4-Lite register interface. This README is short and written to be easy to follow for someone learning FPGA design.

---

## Overview

This repo contains an AES-128 core and a simple AXI4-Lite slave to load the key and data. It focuses on clarity and learnability rather than advanced verification or production features.

Key points:
- Iterative AES-128 implementation (11 rounds)
- Simple AXI4-Lite register interface for control and data
- A basic testbench for functional simulation

---

## Block Diagram

AXI4-Lite Master (Host)
   |
┌──▼──┐
│AXI   │
│Slave │
└──┬───┘
   |
┌──▼──┐
│AES   │
│Core  │
└──────┘

The AES core runs one round per clock cycle. A control register starts the operation and a status register indicates completion.

---

## Registers (brief)

- 0x00–0x0C: KEY[3:0]  — 128-bit key (4 × 32-bit words)
- 0x10–0x1C: DIN[3:0]  — 128-bit input data
- 0x20–0x2C: DOUT[3:0] — 128-bit output data (read-only)
- 0x30: CTRL  — start, enc/dec select, key enable
- 0x34: STATUS — done flag

Notes: start is implemented as a single-cycle pulse on write to CTRL. The register file is intentionally simple.

---

## Project layout (important files)

- AES_encryption_decryption_top.v   — top-level wrapper
- AES_encryption_core.v             — iterative encryption core
- AES_decryption_core.v             — iterative decryption core
- AES_AXI_Lite_slave.sv             — AXI4-Lite slave and registers
- ExpandKey.v                       — key schedule
- SubBytes.v / ShiftRows.v / MixColumns.v — AES primitives
- testbench_tb.sv                   — simple simulation testbench

---

## How to run (quick)

1. Clone this repo
2. Open Vivado and create a project for your target (example: xc7a35tcpg236-1)
3. Add the .v / .sv source files and set the top module
4. Run simulation with the provided testbench or synthesize for your board

---

If you want more detailed instructions, examples, or the original UVM verification content restored, I can add that back in later.