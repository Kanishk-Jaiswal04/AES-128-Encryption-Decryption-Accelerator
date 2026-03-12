`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 12:48:07 AM
// Design Name: 
// Module Name: InvMixColumns
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


module InvMixColumns(
    input [127:0] in_block, 
    output [127:0] out_block
    );
    
    genvar i;
    generate 
        for (i = 0; i < 4; i = i + 1) begin : invmixcolumn
            inv_mix_single_column invmix (
                // i=0 maps to [127:96], i=1 to [95:64], etc.
                .in_word  (in_block[127 - i*32 : 96 - i*32]),
                .out_word (out_block[127 - i*32 : 96 - i*32])
            );
        end
    endgenerate
    
endmodule
