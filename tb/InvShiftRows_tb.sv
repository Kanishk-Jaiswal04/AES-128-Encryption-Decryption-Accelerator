`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 01:40:33 AM
// Design Name: 
// Module Name: InvShiftRows_tb
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


module InvShiftRows_tb;

    logic  [127:0] in_block;
    logic [127:0] out_block;

    InvShiftRows dut (
        .in_block(in_block),
        .out_block(out_block)
    );

    initial begin
        // Fill bytes with their index value
        // b0 = 00, b1 = 01, ..., b15 = 0F
        in_block = 128'h52a4c89485116a28e3cf2fd7f6505e07;

        #10;

        $display("Input: %h", in_block);

        $display("\nAfter ShiftRows (LSB->MSB):");
        $display("Output: %h", out_block);

        if (out_block === 128'h52502f2885a45ed7e311c807f6cf6a94)
            $display("\nPASS: InvShiftRows correct");
        else
            $display("\nFAIL: InvShiftRows incorrect");

        $finish;
    end

endmodule
