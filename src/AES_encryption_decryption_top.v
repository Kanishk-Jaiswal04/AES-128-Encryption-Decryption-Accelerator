`timescale 1ns / 1ps
// =============================================================================
// Module  : AES_encryption_decryption_top
// Brief   : Top-level wrapper instantiating both AES-128 encryption and
//           decryption cores. enc_dec_en steers start and selects output.
//
//   enc_dec_en = 1 → encryption path (text_input treated as plaintext)
//   enc_dec_en = 0 → decryption path (text_input treated as ciphertext)
//
// Both cores run in parallel but only one receives the start pulse.
// Outputs are muxed; the inactive core output is ignored.
//
// Author  : Kanishk Jaiswal
// Target  : Xilinx Artix-7 (Basys 3 / PYNQ-Z2)
// =============================================================================

module AES_encryption_decryption_top(
    input          clk,
    input          rst,
    input          start,
    input          enc_dec_en, // 1 = encrypt, 0 = decrypt
    input          key_en_in,  // Passed to decryption core for key expansion control
    input  [127:0] text_input,
    input  [127:0] key,
    output [127:0] text_output,
    output         done
);

    wire [127:0] text_out_enc, text_out_dec;
    wire         done_enc, done_dec;
    reg          start_enc, start_dec;

    // Output mux — select active core result
    assign text_output = enc_dec_en ? text_out_enc : text_out_dec;
    assign done        = enc_dec_en ? done_enc     : done_dec;

    // Steer start pulse to the correct core only; prevent spurious triggers
    always @(*) begin
        start_enc = 1'b0;
        start_dec = 1'b0;
        if (start) begin
            if (enc_dec_en) start_enc = 1'b1;
            else            start_dec = 1'b1;
        end
    end

    AES_encryption_core encrypt (
        .clk(clk), .rst(rst), .start(start_enc),
        .plaintext(text_input), .key(key),
        .ciphertext(text_out_enc), .done(done_enc)
    );

    AES_decryption_core decrypt (
        .clk(clk), .rst(rst), .start(start_dec),
        .key_en(key_en_in), .ciphertext(text_input), .key(key),
        .plaintext(text_out_dec), .done(done_dec)
    );

endmodule
