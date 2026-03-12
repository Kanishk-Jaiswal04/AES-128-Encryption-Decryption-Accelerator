module inv_mix_single_column(
    input [31:0] in_word,
    output [31:0] out_word
    );

    wire [7:0] s0 = in_word[31:24];
    wire [7:0] s1 = in_word[23:16];
    wire [7:0] s2 = in_word[15:8];
    wire [7:0] s3 = in_word[7:0];

    // xtime is multiplication by {02}
    function [7:0] xtime(input [7:0] b);
        xtime = (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    // Helper functions for larger constants
    function [7:0] mul09(input [7:0] b);
        mul09 = xtime(xtime(xtime(b))) ^ b; // (b*8) ^ b
    endfunction

    function [7:0] mul0b (input [7:0] b);
        mul0b  = xtime(xtime(xtime(b))) ^ xtime(b) ^ b; // (b*8) ^ (b*2) ^ b
    endfunction

    function [7:0] mul0d(input [7:0] b);
        mul0d = xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ b; // (b*8) ^ (b*4) ^ b
    endfunction

    function [7:0] mul0e(input [7:0] b);
        mul0e = xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ xtime(b); // (b*8) ^ (b*4) ^ (b*2)
    endfunction

    // Matrix Multiplication logic
    assign out_word[31:24] = mul0e(s0) ^ mul0b (s1) ^ mul0d(s2) ^ mul09(s3);
    assign out_word[23:16] = mul09(s0)  ^ mul0e(s1) ^ mul0b (s2) ^ mul0d(s3);
    assign out_word[15:8]  = mul0d(s0) ^ mul09(s1)  ^ mul0e(s2) ^ mul0b (s3);
    assign out_word[7:0]   = mul0b (s0) ^ mul0d(s1) ^ mul09(s2)  ^ mul0e(s3);

endmodule