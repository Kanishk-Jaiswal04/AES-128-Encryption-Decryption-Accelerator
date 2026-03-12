//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 10:57:14 PM
// Design Name: 
// Module Name: SubBytes
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

module SubBytes(
    input  wire [127:0] in_block,
    output wire [127:0] out_block
);

    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : subbytes
            sbox inst (
                .in_byte  (in_block[i*8 + 7 : i*8]),
                .out_byte (out_block[i*8 + 7 : i*8])
            );
        end
    endgenerate

endmodule

