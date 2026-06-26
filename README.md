# AES-128 Encryption/Decryption SoC Accelerator

A high-performance AES-128 encryption/decryption engine in SystemVerilog, integrated with a pipelined AXI4-Lite slave interface environment. Targets the Xilinx Artix-7 (PYNQ-Z2 / Basys 3).

---

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [AXI4-Lite Interface](#axi4-lite-interface)
- [Simulation Waveform](#simulation-waveform)
- [Performance & Results](#performance--results)
- [Tools & Target Platform](#tools--target-platform)

---

## Overview

This project implements a complete AES-128 SoC accelerator with the following highlights:

- Iterative AES-128 engine supporting both encryption and decryption, completing in **11 clock cycles**
- Pipelined AXI4-Lite slave with unified register buffer, Fmax **~102.72 MHz** (WNS +0.265 ns at 100 MHz)
- Full UVM testbench with constrained-random stimulus, reference predictor, automated scoreboard, and **100% functional coverage** against NIST KAT vectors

---

## Architecture

```
         AXI4-Lite Master (Host / PS)
                    |
         ┌──────────▼──────────┐
         │   AXI4-Lite Slave   │
         │  (Unified Reg Buffer│
         │   + AXI Handshaking)│
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │    AES-128 Engine   │
         │  ┌───────────────┐  │
         │  │  Key Schedule │  │
         │  │  (ExpandKey)  │  │
         │  └───────┬───────┘  │
         │  ┌───────▼───────┐  │
         │  │  SubBytes     │  │
         │  │  ShiftRows    │  │
         │  │  MixColumns   │  │
         │  │  AddRoundKey  │  │
         │  └───────────────┘  │
         └──────────┬──────────┘
                    │
              128-bit Ciphertext / Plaintext Output
```

The AES engine is iterative, one round per clock cycle. The encryption and decryption cores run in parallel; `enc_dec_en` steers the start pulse and output mux.

---

## AXI4-Lite Interface

Memory-mapped register interface (32-bit words, byte-addressable):

| Offset       | Name       | Access     | Description                          |
|--------------|------------|------------|--------------------------------------|
| 0x00 – 0x0C  | KEY[3:0]   | Write      | 128-bit AES key (4 × 32-bit words)   |
| 0x10 – 0x1C  | DIN[3:0]   | Write      | 128-bit plaintext / ciphertext input |
| 0x20 – 0x2C  | DOUT[3:0]  | Read-only  | 128-bit output (written by AES core) |
| 0x30         | CTRL       | Write      | [0]=start [1]=enc_dec_en [2]=key_en  |
| 0x34         | STATUS     | Read/Write | [0]=done (set by core, clearable)    |
| 0x38 – 0x3C  | —          | —          | Reserved                             |

**Key design decisions:**
- Unified `slv_mem` array for all register I/O which avoids multiple-driver conflicts that arise from separate write/read/DUT output paths
- Rising-edge detect on CTRL[0] generates a clean one-cycle start pulse which prevents re-triggering if the master writes the register multiple times
- Priority-encoded write logic (AES done > start pulse > AXI write) in a single `always_ff` block
- Output registers [8–11] are write-protected from AXI master; only the AES core can update them
- Auto-clear of STATUS[0] on start pulse ensures done flag is never stale across back-to-back operations

---

## Simulation Waveform

![AXI4-Lite Simulation Waveform](waveform.png)

The waveform captures a complete AXI4-Lite transaction:

- **0–300 ns** — Write phase: `awvalid`/`awready` and `wvalid`/`wready` handshaking loads key and plaintext registers. `bvalid` confirms each write response.
- **300–500 ns** — AES core processes 11 encryption rounds internally.
- **500–700 ns** — Read phase: `arvalid`/`arready` steps through output register offsets `0x20 → 0x24 → 0x28 → 0x2C`. `rdata` returns ciphertext word `762a5ab5` on the final read.

---

## Performance & Results

| Metric                     | Value                          |
|----------------------------|--------------------------------|
| Target Clock               | 100 MHz                        |
| Fmax (achieved)            | ~102.72 MHz                    |
| WNS                        | +0.265 ns                      |
| AES Core Latency           | 11 cycles                      |
| Full System Latency        | ~40 cycles (inc. AXI overhead) |
| Throughput                 | 320 Mbps                       |
| AXI Bus Bandwidth (raw)    | 1.6 Gbps                       |
| Bus Efficiency             | ~20%                           |
| Functional Coverage        | 100% (NIST KAT verified)       |

---

## Tools & Target Platform

| Item         | Detail                          |
|--------------|---------------------------------|
| FPGA         | Xilinx Artix-7 XC7A35T          |
| Board        | Basys 3                         |
| Toolchain    | Vivado 2024.x                   |
| Standard     | NIST FIPS-197                   |
