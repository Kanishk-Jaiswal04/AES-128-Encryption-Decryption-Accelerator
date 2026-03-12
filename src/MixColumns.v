`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2026 07:36:13 PM
// Design Name: 
// Module Name: mix_single_column
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

module MixColumns(
    input [127:0] in_block, 
    output [127:0] out_block
    );
    
    genvar i;
    generate 
        for (i = 0; i < 4; i = i + 1) begin : mixcolumn
            mix_single_column mix (
                // i=0 maps to [127:96], i=1 to [95:64], etc.
                .in_word  (in_block[127 - i*32 : 96 - i*32]),
                .out_word (out_block[127 - i*32 : 96 - i*32])
            );
        end
    endgenerate

endmodule 