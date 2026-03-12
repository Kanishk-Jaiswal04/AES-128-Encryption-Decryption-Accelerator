`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 10:57:14 PM
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


module mix_single_column(
    input [31:0] in_word, 
    output [31:0] out_word
    );
    
    wire [7:0] s0 = in_word[31:24];
    wire [7:0] s1 = in_word[23:16];
    wire [7:0] s2 = in_word[15:8];
    wire [7:0] s3 = in_word[7:0];

    function [7:0] xtime;
        input [7:0] b;
        xtime = (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    // s0' = 2*s0 + 3*s1 + 1*s2 + 1*s3
    assign out_word[31:24] = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3;
    
    // s1' = 1*s0 + 2*s1 + 3*s2 + 1*s3
    assign out_word[23:16] = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
   
    // s2' = 1*s0 + 1*s1 + 2*s2 + 3*s3
    assign out_word[15:8]  = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
   
    // s3' = 3*s0 + 1*s1 + 1*s2 + 2*s3
    assign out_word[7:0]   = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);
    
endmodule
