`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 01:20:59 AM
// Design Name: 
// Module Name: InvSubBytes_tb
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


module InvSubBytes_tb;

logic [127:0] block_in;
logic [127:0] block_out;

InvSubBytes dut (.in_block(block_in), .out_block(block_out));

initial begin
    block_in = 128'h49ded28945db96f17f39871a7702533b;
    
    #10;
    
    $display("Input  : %h", block_in);
    $display("Output : %h", block_out);

    // Expected InvSubBytes output
    if (block_out === 128'ha49c7ff2689f352b6b5bea43026a5049)
        $display("PASS: InvSubBytes correct");
    else
        $display("FAIL: InvSubBytes incorrect");

    $finish;
end
endmodule
