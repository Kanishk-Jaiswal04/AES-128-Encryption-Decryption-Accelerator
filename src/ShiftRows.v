`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 10:57:14 PM
// Design Name: 
// Module Name: ShiftRows
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


module ShiftRows(
    input [127:0] in_block,
    output [127:0] out_block
);      

        // All The Rows Start Counting from the Back due to the Big Endianness of the Format 
        // So it goes from [127:120] as the first byte, [119:112] as the second byte and so on
        // Row 0: No Shift (Bytes 0, 4, 8, 12)
        // Row 1: Left Shift 1 (Bytes 5, 9, 13, 1)
        // Row 2: Left Shift 2 (Bytes 10, 14, 2, 6)
        // Row 3: Left Shift 3 (Bytes 15, 3, 7, 11)
        // Take transpose for correct ordering for assignment
        // |0 5 10 15 |
        // |4 9 14 3  |
        // |8 13 2 7  |
        // |12 1 6 11 |
    assign out_block = {
    
        // Row 0: Bytes 0, 5, 10, 15
        in_block[127:120], in_block[87:80], in_block[47:40], in_block[7:0],
    
        // Row 1: Bytes 4, 9, 14, 3
        in_block[95:88],   in_block[55:48], in_block[15:8], in_block[103:96],
    
        // Row 2: Bytes 8, 13, 2, 7
        in_block[63:56],   in_block[23:16],   in_block[111:104], in_block[71:64],
    
        // Row 3: Bytes 12, 1, 6, 11
        in_block[31:24],     in_block[119:112], in_block[79:72], in_block[39:32]
    };

endmodule

