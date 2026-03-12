module AES_decryption_core_tb;

    // Clock and Control
    logic clk;
    logic rst;
    logic start;
    logic key_en;
    
    // Data
    logic [127:0] ciphertext;
    logic [127:0] key;
    logic [127:0] plaintext;
    logic done;

    // Metrics
    integer cycle_count;

    // Instantiate DUT
    AES_decryption_core dut (.*);

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Cycle Counter
    always @(posedge clk) begin
        if (state_is_active()) cycle_count <= cycle_count + 1;
        else cycle_count <= 0;
    end

    function logic state_is_active();
        return (dut.state != 2'b00); // Not IDLE
    endfunction

    // --- MAIN TEST SEQUENCER ---
    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING AES DECRYPTION TEST SUITE");
        $display("---------------------------------------------------------");
        
        initialize();
        do_reset();

        // TEST CASE 1: Full Expansion + Decryption
        // Expected Plaintext: 3243f6a8885a308d313198a2e0370734
        run_decryption_test(
            128'h3925841d02dc09fbdc118597196a0b32, // Cipher
            128'h2b7e151628aed2a6abf7158809cf4f3c, // Key
            128'h3243f6a8885a308d313198a2e0370734, // Expected
            1'b1,                                  // key_en 
            "Fresh Key Expansion Mode"
        );

        // TEST CASE 2: Direct Mode (Use Buffer)
        // We use the same key, but set key_en to 0 to test the 11-cycle path
        run_decryption_test(
            128'h3925841d02dc09fbdc118597196a0b32,
            128'h2b7e151628aed2a6abf7158809cf4f3c,
            128'h3243f6a8885a308d313198a2e0370734,
            1'b0,                                  // key_en 
            "Direct Buffer Mode"
        );

        $display("---------------------------------------------------------");
        $display("ALL TESTS COMPLETED");
        $display("---------------------------------------------------------");
        #50;
        $finish;
    end

    // --- HELPER TASKS ---

    task initialize();
        rst = 1;
        start = 0;
        key_en = 0;
        ciphertext = 0;
        key = 0;
        cycle_count = 0;
    endtask

    task do_reset();
        repeat(5) @(posedge clk);
        rst <= 0;
        @(posedge clk);
        $display("[%0t] System Reset Released", $time);
    endtask

    task run_decryption_test(
        input [127:0] c_text,
        input [127:0] k_val,
        input [127:0] expected,
        input k_en,
        input string test_name
    );
        begin
            ciphertext = c_text;
            key = k_val;
            key_en = k_en;
            
            @(posedge clk);
            start <= 1;
            @(posedge clk);
            start <= 0;

            $display("[%0t] Launching Test: %s", $time, test_name);
            
            wait(done);
            
            // Check Result
            if (plaintext === expected) begin
                $display("  >> SUCCESS: Matches NIST vector.");
            end else begin
                $display("  >> ERROR: Mismatch!");
                $display("     Expected: %h", expected);
                $display("     Got:      %h", plaintext);
            end
            
            $display("     Cycles Taken: %0d", cycle_count);
            repeat(2) @(posedge clk);
        end
    endtask

endmodule