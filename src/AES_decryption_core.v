`timescale 1ns / 1ps
// =============================================================================
// Module  : AES_decryption_core
// Brief   : Iterative AES-128 decryption using the Equivalent Inverse Cipher
//           (NIST FIPS-197 §5.3.5). Completes in 11 cycles at 100 MHz.
//
// Two-phase operation:
//   KEY_GENERATION  (key_en=1) : Expands key and pre-applies InvMixColumns to
//                                round keys 1–9 so they commute with the
//                                InvMixColumns step in the cipher datapath.
//                                key_buffer[0] and [10] are stored raw.
//   CIPHER_ROUND               : Runs rounds 9→0 using pre-processed key_buffer.
//                                Round 0 skips InvMixColumns (per FIPS-197).
//
// If key_en=0, KEY_GENERATION is skipped (reuse key_buffer from previous op).
//
// Author  : Kanishk Jaiswal
// Target  : Xilinx Artix-7 (Basys 3 / PYNQ-Z2)
// =============================================================================

module AES_decryption_core(
    input              clk,
    input              rst,        // Active-high synchronous reset
    input              start,      // Single-cycle pulse to begin operation
    input              key_en,     // 1 = run key expansion; 0 = reuse key_buffer
    input      [127:0] ciphertext,
    input      [127:0] key,
    output reg [127:0] plaintext,  // Valid when done = 1
    output reg         done        // Single-cycle pulse
);

    parameter IDLE           = 2'b00;
    parameter KEY_GENERATION = 2'b01;
    parameter CIPHER_ROUND   = 2'b10;
    parameter STOP           = 2'b11; // Reserved

    reg [1:0]   state;
    reg [3:0]   round_cnt; // Counts up during KEY_GENERATION, down during CIPHER_ROUND
    reg [127:0] text_reg;
    reg [127:0] key_reg;

    // key_buffer[0]   = raw original key   (final AddRoundKey)
    // key_buffer[1–9] = InvMixColumns(ExpandedKey[r])  (pre-processed for datapath commutation)
    // key_buffer[10]  = raw ExpandedKey[10] (initial ciphertext XOR)
    reg [127:0] key_buffer [0:10];

    wire [127:0] key_out, invsub_out, invshift_out, invmix_in, invmix_out;

    // InvMixColumns is shared between key pre-processing and the cipher datapath.
    // Tie to 0 in IDLE/STOP to avoid unnecessary toggling (power).
    assign invmix_in = (state == KEY_GENERATION) ? key_out      :
                       (state == CIPHER_ROUND)   ? invshift_out :
                                                   128'b0;

    ExpandKey    keygen   (.clk(clk), .round_no(round_cnt), .in_key(key_reg), .out_key(key_out));
    InvSubBytes  invsub   (.in_block(text_reg),    .out_block(invsub_out));
    InvShiftRows invshift (.in_block(invsub_out),  .out_block(invshift_out));
    InvMixColumns invmix  (.in_block(invmix_in),   .out_block(invmix_out));

    always @(posedge clk) begin
        if (rst) begin
            round_cnt <= 'b0;
            key_reg   <= 'b0;
            text_reg  <= 'b0;
            state     <= IDLE;
            plaintext <= 'b0;
            done      <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    key_reg <= key; // Latch key every cycle so it's ready on start
                    done    <= 1'b0;
                    if (start) begin
                        if (key_en) begin
                            key_buffer[0] <= key_reg;
                            round_cnt     <= 4'd1;
                            state         <= KEY_GENERATION;
                        end else begin
                            // Skip expansion — XOR ciphertext with pre-stored last round key
                            text_reg  <= ciphertext ^ key_buffer[10];
                            round_cnt <= 4'd9;
                            state     <= CIPHER_ROUND;
                        end
                    end
                end

                KEY_GENERATION: begin
                    if (round_cnt == 4'd10) begin
                        key_buffer[10] <= key_out;              // Raw — no InvMixColumns
                        text_reg       <= ciphertext ^ key_out; // Initial AddRoundKey
                        round_cnt      <= 4'd9;
                        state          <= CIPHER_ROUND;
                    end else begin
                        key_buffer[round_cnt] <= invmix_out; // Pre-process for datapath commutation
                        key_reg               <= key_out;
                        round_cnt             <= round_cnt + 1'b1;
                    end
                end

                CIPHER_ROUND: begin
                    if (round_cnt == 4'd0) begin
                        // Final round: InvMixColumns is omitted per FIPS-197 §5.3
                        plaintext <= invshift_out ^ key_buffer[0];
                        done      <= 1'b1;
                        state     <= IDLE;
                    end else begin
                        text_reg  <= invmix_out ^ key_buffer[round_cnt];
                        round_cnt <= round_cnt - 1'b1;
                    end
                end

            endcase
        end
    end

endmodule
