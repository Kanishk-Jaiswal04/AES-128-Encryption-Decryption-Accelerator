`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 02:50:42 AM
// Design Name: 
// Module Name: AES_encryption_decryption_core_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module AES_enc_dec_wrapper_tb;

    // Signals
    logic clk;
    logic rst;
    logic start;
    logic enc_dec_en;
    logic key_en_in;
    logic [127:0] text_input;
    logic [127:0] key;
    logic [127:0] text_output;
    logic done;

    // DUT Instance
    AES_encryption_decryption_top dut (.*);

    // Clock Generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // NIST Test Vectors
    localparam [127:0] NIST_KEY        = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_PLAINTEXT  = 128'h3243f6a8885a308d313198a2e0370734;
    localparam [127:0] NIST_CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32;

    initial begin
        // --- Initialization ---
        rst = 1;
        start = 0;
        enc_dec_en = 0;
        key_en_in = 1;
        text_input = 0;
        key = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        $display("[%0t] Reset De-asserted. Starting Tests...", $time);

        // --- TEST 1: ENCRYPTION ---
        $display("\n--- TEST 1: Encryption Mode ---");
        enc_dec_en = 1; // Set to Encryption
        key        = NIST_KEY;
        text_input = NIST_PLAINTEXT;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done);
        if (text_output === NIST_CIPHERTEXT)
            $display("SUCCESS: Encryption output matches NIST (%h)", text_output);
        else
            $display("FAILURE: Encryption mismatch! Got %h", text_output);

        repeat(5) @(posedge clk);

        // --- TEST 2: DECRYPTION (Cold Start) ---
        $display("\n--- TEST 2: Decryption Mode (Cold Key Expansion) ---");
        enc_dec_en = 0; // Set to Decryption
        key_en_in  = 1; // Force new key expansion
        key        = NIST_KEY;
        text_input = NIST_CIPHERTEXT;

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done);
        if (text_output === NIST_PLAINTEXT)
            $display("SUCCESS: Decryption output matches NIST (%h)", text_output);
        else
            $display("FAILURE: Decryption mismatch! Got %h", text_output);

        repeat(5) @(posedge clk);

        // --- TEST 3: DECRYPTION (Warm Start / Buffer Mode) ---
        $display("\n--- TEST 3: Decryption Mode (Using Buffered Key) ---");
        key_en_in  = 0; // Skip expansion (should take ~10 cycles)
        text_input = NIST_CIPHERTEXT;

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done);
        if (text_output === NIST_PLAINTEXT)
            $display("SUCCESS: Buffer mode decryption works!");
        else
            $display("FAILURE: Buffer mode failed!");

        $display("\n--- ALL WRAPPER TESTS COMPLETE ---");
        #100;
        $finish;
    end

endmodule