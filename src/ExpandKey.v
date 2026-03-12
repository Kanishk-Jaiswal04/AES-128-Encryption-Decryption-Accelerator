`timescale 1ns / 1ps
// =============================================================================
// Module  : ExpandKey
// Brief   : AES-128 key schedule — computes ExpandedKey[r] from ExpandedKey[r-1].
//           One round expansion per call; instantiated iteratively by the FSM.
//
// Key expansion per round (FIPS-197 §5.2):
//   t    = SubWord(RotWord(w3)) XOR Rcon[r]
//   w0n  = w0 XOR t
//   w1n  = w1 XOR w0n
//   w2n  = w2 XOR w1n
//   w3n  = w3 XOR w2n
//
// Clocked on negedge to give the FSM (posedge) a full half-cycle setup margin
// before out_key is consumed on the next posedge.
//
// Author  : Kanishk Jaiswal
// =============================================================================

module ExpandKey(
    input            clk,
    input      [3:0] round_no,   // Current round index (1–10)
    input      [127:0] in_key,   // ExpandedKey[r-1]
    output reg [127:0] out_key   // ExpandedKey[r]
);

    // Split input key into four 32-bit words
    wire [31:0] w0 = in_key[127:96];
    wire [31:0] w1 = in_key[95:64];
    wire [31:0] w2 = in_key[63:32];
    wire [31:0] w3 = in_key[31:0];

    // RotWord: byte-rotate w3 left by one byte [b0,b1,b2,b3] → [b1,b2,b3,b0]
    wire [31:0] rot_w3 = rotword(w3);

    // SubWord: apply S-Box substitution to each byte of the rotated word
    wire [31:0] sbox_wire;
    sbox inst1 (.in_byte(rot_w3[31:24]), .out_byte(sbox_wire[31:24]));
    sbox inst2 (.in_byte(rot_w3[23:16]), .out_byte(sbox_wire[23:16]));
    sbox inst3 (.in_byte(rot_w3[15:8]),  .out_byte(sbox_wire[15:8]));
    sbox inst4 (.in_byte(rot_w3[7:0]),   .out_byte(sbox_wire[7:0]));

    // XOR with round constant; Rcon values are powers of 2 in GF(2^8)
    wire [31:0] t   = sbox_wire ^ rcon(round_no);

    wire [31:0] w0n = w0 ^ t;
    wire [31:0] w1n = w1 ^ w0n;
    wire [31:0] w2n = w2 ^ w1n;
    wire [31:0] w3n = w3 ^ w2n;

    // Register on negedge for half-cycle setup margin ahead of posedge FSM
    always @(negedge clk)
        out_key <= {w0n, w1n, w2n, w3n};

    // RotWord: [b0,b1,b2,b3] → [b1,b2,b3,b0]
    function [31:0] rotword;
        input [31:0] w;
        rotword = {w[23:0], w[31:24]};
    endfunction

    // Rcon[r] = (x^(r-1) mod p(x), 0x00, 0x00, 0x00) in GF(2^8)
    // p(x) = x^8 + x^4 + x^3 + x + 1 (AES irreducible polynomial)
    // Values above 0x80 reduce modulo p(x): e.g. 0x1b = 0x100 mod p(x)
    function [31:0] rcon;
        input [3:0] r;
        case (r)
            4'd1:  rcon = 32'h01000000;
            4'd2:  rcon = 32'h02000000;
            4'd3:  rcon = 32'h04000000;
            4'd4:  rcon = 32'h08000000;
            4'd5:  rcon = 32'h10000000;
            4'd6:  rcon = 32'h20000000;
            4'd7:  rcon = 32'h40000000;
            4'd8:  rcon = 32'h80000000;
            4'd9:  rcon = 32'h1b000000; // 0x80 << 1 reduced mod p(x)
            4'd10: rcon = 32'h36000000; // 0x1b << 1 in GF(2^8)
            default: rcon = 32'h00000000;
        endcase
    endfunction

endmodule
