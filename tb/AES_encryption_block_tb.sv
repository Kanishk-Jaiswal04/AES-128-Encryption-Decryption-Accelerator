`timescale 1ns / 1ps

module AES_encryption_block_tb;

    // Inputs
    logic clk, rst, start;
    logic [127:0] plaintext, key;
    // Outputs
    logic [127:0] ciphertext;
    logic done;

    // DUT Instance
    AES_encryption_core dut (.*);

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Internal Monitor - Prints every round status
    always @(posedge clk) begin
        if (dut.state != 2'b00) begin // If NOT IDLE
            $display("--- Round %0d ---", dut.round_cnt);
            $display("Text Reg: %h", dut.text_reg);
            $display("Key Out:  %h", dut.key_out);
            $display("Sub:      %h", dut.sub_out);
            $display("Shift:    %h", dut.shift_out);
            if (dut.round_cnt < 10) 
                $display("Mix:      %h", dut.mix_out);
            $display("-----------------");
        end
    end

    // Task to run a single encryption test
    task run_test(input [127:0] p_in, input [127:0] k_in, input [127:0] expected);
        begin
            plaintext = p_in;
            key = k_in;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for core to finish
            wait(done);
            
            if (ciphertext === expected)
                $display("\n[SUCCESS] Expected: %h\n          Got:      %h\n", expected, ciphertext);
            else
                $display("\n[ERROR]   Expected: %h\n          Got:      %h\n", expected, ciphertext);
            
            @(posedge clk); // Gap between vectors
        end
    endtask

    initial begin
        // Reset
        rst = 1; start = 0;
        #50 rst = 0;
        #20;

        $display("STARTING CONSECUTIVE VECTOR TEST");

        // Vector 1: Standard NIST
        run_test(
            128'h3243f6a8885a308d313198a2e0370734, 
            128'h2b7e151628aed2a6abf7158809cf4f3c, 
            128'h3925841d02dc09fbdc118597196a0b32
        );

        // Vector 2: Another standard block
        // (Example: Round 0 check or a second block from the same key)
        run_test(
            128'h00112233445566778899aabbccddeeff, 
            128'h000102030405060708090a0b0c0d0e0f, 
            128'h69c4e0d86a7b0430d8cdb78070b4c55a
        );

        #50;
        $finish;
    end

endmodule
