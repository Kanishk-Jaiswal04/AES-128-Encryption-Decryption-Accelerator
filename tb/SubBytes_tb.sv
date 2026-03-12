`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 11:07:01 PM
// Design Name: 
// Module Name: SubBytes_tb
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


module SubBytes_tb;

logic [127:0] block_in;
logic [127:0] block_out;

SubBytes dut (.in_block(block_in), .out_block(block_out));

initial begin
    block_in = 128'h260e2e173d41b77de86472a9fdd28b25;
    
    #10;
    
    $display("Input  : %h", block_in);
    $display("Output : %h", block_out);

    // Expected SubBytes output
    if (block_out === 128'hf7ab31f02783a9ff9b4340d354b53d3f)
        $display("PASS: SubBytes correct");
    else
        $display("FAIL: SubBytes incorrect");

    $finish;
end
endmodule
