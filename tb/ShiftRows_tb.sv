`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 11:51:44 PM
// Design Name: 
// Module Name: ShiftRows_tb
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

module ShiftRows_tb;

    logic  [127:0] in_block;
    logic [127:0] out_block;

    ShiftRows dut (
        .in_block(in_block),
        .out_block(out_block)
    );

    initial begin
        // Fill bytes with their index value
        // b0 = 00, b1 = 01, ..., b15 = 0F
        in_block = 128'hbe832cc8d43b86c00ae1d44dda64f2fe;

        #10;

        $display("Input: %h", in_block);

        $display("\nAfter ShiftRows (LSB->MSB):");
        $display("Output: %h", out_block);

        if (out_block === 128'hbe3bd4fed4e1f2c80a642cc0da83864d)
            $display("\nPASS: ShiftRows correct");
        else
            $display("\nFAIL: ShiftRows incorrect");

        $finish;
    end

endmodule

