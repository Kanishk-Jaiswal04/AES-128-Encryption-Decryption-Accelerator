`timescale 1ns / 1ps
// =============================================================================
// Module  : AES_encryption_core
// Brief   : Iterative AES-128 encryption engine. Completes in 11 cycles at
//           100 MHz (10 cipher rounds + 1 STOP cycle to register output).
//
// Datapath per cycle (CIPHER_ROUND):
//   text_reg → SubBytes → ShiftRows → MixColumns → XOR key_out → text_reg
//   Round 10 bypasses MixColumns (per FIPS-197 §5.1 final round rule).
//
// Key schedule: ExpandKey is combinational relative to key_reg. key_reg is
//   updated to key_out at the end of each round so that ExpandKey produces
//   the correct next round key on the following cycle.
//
// Author  : Kanishk Jaiswal
// Target  : Xilinx Artix-7 (Basys 3 / PYNQ-Z2)
// =============================================================================

module AES_encryption_core(
    input              clk,
    input              rst,       // Active-high synchronous reset
    input              start,     // Single-cycle pulse to begin encryption
    input      [127:0] plaintext,
    input      [127:0] key,
    output reg [127:0] ciphertext, // Valid when done = 1
    output reg         done        // Single-cycle pulse
);

    parameter IDLE         = 2'b00;
    parameter CIPHER_ROUND = 2'b01;
    parameter STOP         = 2'b10; // One extra cycle to register ciphertext output

    reg [1:0]   state;
    reg [3:0]   round_cnt;
    reg [127:0] text_reg;
    reg [127:0] key_reg;

    wire [127:0] key_out;   // Next expanded round key (combinational from key_reg)
    wire [127:0] sub_out;   // SubBytes output
    wire [127:0] shift_out; // ShiftRows output
    wire [127:0] mix_out;   // MixColumns output

    ExpandKey  keygen    (.clk(clk), .round_no(round_cnt), .in_key(key_reg), .out_key(key_out));
    SubBytes   bytesub   (.in_block(text_reg),  .out_block(sub_out));
    ShiftRows  rowshift  (.in_block(sub_out),   .out_block(shift_out));
    MixColumns columnmix (.in_block(shift_out), .out_block(mix_out));

    always @(posedge clk) begin
        if (rst) begin
            ciphertext <= 0;
            done       <= 0;
            round_cnt  <= 0;
            text_reg   <= 0;
            key_reg    <= 0;
            state      <= IDLE;
        end else begin
            case (state)

                IDLE: begin
                    done    <= 1'b0;
                    key_reg <= key;
                    if (start) begin
                        text_reg  <= plaintext ^ key; // Round 0: initial AddRoundKey
                        round_cnt <= 4'd1;
                        state     <= CIPHER_ROUND;
                    end
                end

                CIPHER_ROUND: begin
                    if (round_cnt == 4'd10) begin
                        // Final round: MixColumns is omitted per FIPS-197 §5.1
                        // key_out here is ExpandedKey[10], derived from key_reg set last cycle
                        text_reg <= shift_out ^ key_out;
                        state    <= STOP;
                    end else begin
                        text_reg  <= mix_out ^ key_out;
                        key_reg   <= key_out; // Advance key_reg so ExpandKey produces next round key
                        round_cnt <= round_cnt + 1'b1;
                    end
                end

                // Extra cycle needed: text_reg holds final result but ciphertext
                // output register and done flag are updated here to meet timing.
                STOP: begin
                    ciphertext <= text_reg;
                    done       <= 1'b1;
                    state      <= IDLE;
                end

            endcase
        end
    end

endmodule
