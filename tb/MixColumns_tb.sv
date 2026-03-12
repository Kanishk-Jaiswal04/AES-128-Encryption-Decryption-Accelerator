`timescale 1ns/1ps

module MixColumns_tb;

    logic [127:0] in_block;
    logic [127:0] out_block;

    MixColumns dut (
        .in_block(in_block),
        .out_block(out_block)
    );

    initial begin
        // Only first column is meaningful; others set to zero
        in_block = 128'hd4bf5d30e0b452aeb84111f11e2798e5;

        #10;

        $display("Input : %h",in_block);

        $display("Output : %h",
                 out_block);

        // Expected: 04 66 81 e5
        if (out_block === 128'h046681e5e0cb199a48f8d37a2806264c)
            $display("\nPASS: MixColumns correct");
        else begin
            $display("\nFAIL: MixColumns incorrect");
        end

        $finish;
    end

endmodule
