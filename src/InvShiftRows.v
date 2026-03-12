`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 12:48:07 AM
// Design Name: 
// Module Name: InvShiftRows
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


module InvShiftRows(
    input [127:0] in_block,
    output [127:0] out_block
    );
    
    // All The Rows Start Counting from the Back due to the Big Endianness of the Format 
        // So it goes from [127:120] as the first byte, [119:112] as the second byte and so on
        // Row 0: No Shift (Bytes 0, 4, 8, 12)
        // Row 1: Right Shift 1 (Bytes 13, 1, 5, 9)
        // Row 2: Right Shift 2 (Bytes 10, 14, 2, 6)
        // Row 3: Right Shift 3 (Bytes 7, 11, 15, 3)
        // Take transpose for correct ordering for assignment
        // |0 13 10 7 |
        // |4 1 14 11 |
        // |8 5 2 15 |
        // |12 9 6 3 |
        
    assign out_block = {
    
        // Row 0: Bytes 0, 13, 10, 7
        in_block[127:120], in_block[23:16], in_block[47:40], in_block[71:64],
    
        // Row 1: Bytes 4, 1, 14, 11
        in_block[95:88],   in_block[119:112], in_block[15:8], in_block[39:32],
    
        // Row 2: Bytes 8, 5, 2, 15
        in_block[63:56],   in_block[87:80],   in_block[111:104], in_block[7:0],
    
        // Row 3: Bytes 12, 9, 6, 3
        in_block[31:24],     in_block[55:48], in_block[79:72], in_block[103:96]
    };
endmodule
