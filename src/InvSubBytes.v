`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 12:48:07 AM
// Design Name: 
// Module Name: InvSubBytes
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


module InvSubBytes(
    input [127:0] in_block,
    output [127:0] out_block
    );
    
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : invsubbytes
            InvSbox inst (
                .in_byte  (in_block[i*8 + 7 : i*8]),
                .out_byte (out_block[i*8 + 7 : i*8])
            );
        end
    endgenerate
    
endmodule
