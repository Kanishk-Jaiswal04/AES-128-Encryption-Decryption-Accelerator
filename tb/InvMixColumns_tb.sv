`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 02:15:57 AM
// Design Name: 
// Module Name: InvMixColumns_tb
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


module InvMixColumns_tb;

    logic [127:0] in_block;
    logic [127:0] out_block;

    InvMixColumns dut (
        .in_block(in_block),
        .out_block(out_block)
    );

    initial begin
    
        in_block = 128'h046681e5e0cb199a48f8d37a2806264c;

        #10;

        $display("Input : %h",in_block);

        $display("Output : %h",
                 out_block);

        if (out_block === 128'hd4bf5d30e0b452aeb84111f11e2798e5)
            $display("\nPASS: InvMixColumns correct");
        else begin
            $display("\nFAIL: InvMixColumns incorrect");
        end

        $finish;
    end

endmodule
