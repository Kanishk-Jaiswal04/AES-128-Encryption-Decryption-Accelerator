`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2026 11:29:49 PM
// Design Name: 
// Module Name: ExpandKey_tb
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


module ExpandKey_tb;

logic clk;
logic [3:0] round_no;
logic [127:0] in_block;
logic [127:0] out_block;

ExpandKey dut (.clk(clk), 
               .round_no(round_no), 
               .in_key(in_block), 
               .out_key(out_block)
               );

initial clk = 0;
always #5 clk = ~clk;

initial begin
    // Initialize Inputs
    round_no = 0;
    in_block = 0;
    // Wait for global reset
    #100;
    
    // --- Test Case 1: NIST Standard Key Expansion ---
    // Original Key (Round 0): 2b7e1516 28aed2a6 abf71588 09cf4f3c
    // Expected Round 1 Key:   a0fafe17 88542cb1 23a33939 2a6c7605
    
    $display("Starting AES-128 Key Expansion Test...");
    
    @(posedge clk);
    round_no = 4'd4; 
    in_block = 128'h3d80477d4716fe3e1e237e446d7a883b;
    // Wait for computation (assuming 1 clock cycle for logic to settle)
    @(posedge clk);
    #1; // Small delay to observe output after clock edge
    
    $display("Input Key:  %h", in_block);
    $display("Round:      %d", round_no);
    $display("Output Key: %h", out_block);
    if (out_block === 128'hef44a541a8525b7fb671253bdb0bad00) begin
        $display("SUCCESS: Round 1 key matches NIST standard.");
    end else begin
        $display("ERROR: Round 1 key mismatch!");
    end
    // --- Test Case 2: Verification of Round 2 ---
    // Expected Round 2 Key: f2c295f2 7a96b943 5935807a 7359f67f
    @(posedge clk);
    round_no = 4'd2;
    in_block = 128'ha0fafe1788542cb123a339392a6c7605; // Input is the previous round key
    @(posedge clk);
    #1;
    $display("Round:      %d", round_no);
    $display("Output Key: %h", out_block);
    
    if (out_block === 128'hf2c295f27a96b9435935807a7359f67f) begin
        $display("SUCCESS: Round 2 key matches NIST standard.");
    end else begin
        $display("ERROR: Round 2 key mismatch!");
    end
    #50;
    $finish;
end

endmodule
