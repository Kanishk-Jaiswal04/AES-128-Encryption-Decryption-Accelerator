`timescale 1ns / 1ps

module tb_axi_aes;

    // --- 1. Parameters & Signals ---
    localparam CLK_PERIOD = 10;
    
    reg clk;
    reg rst_n;
    
    // AXI-Lite Signals
    reg [31:0] s_axi_awaddr;
    reg        s_axi_awvalid;
    wire       s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg        s_axi_wvalid;
    wire       s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire       s_axi_bvalid;
    reg        s_axi_bready;
    reg [31:0] s_axi_araddr;
    reg        s_axi_arvalid;
    wire       s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;
    logic [3:0] s_axi_wstrb;

    // Performance Tracking
    real start_time, end_time, total_ns;
    real throughput_mbps;
    reg [31:0] status_reg;

     //--Check the memory integrity from the waveform--
    wire [127:0] slv_mem0 = {dut.slv_mem [0], dut.slv_mem [1], dut.slv_mem [2], dut.slv_mem [3]};

    // --- 2. Clock Generator ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- 3. DUT Instantiation ---
    AES_AXI_Lite_slave dut (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (rst_n),
        .S_AXI_AWADDR  (s_axi_awaddr),
        .S_AXI_AWVALID (s_axi_awvalid),
        .S_AXI_AWREADY (s_axi_awready),
        .S_AXI_WDATA   (s_axi_wdata),
        .S_AXI_WSTRB   (s_axi_wstrb),
        .S_AXI_WVALID  (s_axi_wvalid),
        .S_AXI_WREADY  (s_axi_wready),
        .S_AXI_BRESP   (s_axi_bresp),
        .S_AXI_BVALID  (s_axi_bvalid),
        .S_AXI_BREADY  (s_axi_bready),
        .S_AXI_ARADDR  (s_axi_araddr),
        .S_AXI_ARVALID (s_axi_arvalid),
        .S_AXI_ARREADY (s_axi_arready),
        .S_AXI_RDATA   (s_axi_rdata),
        .S_AXI_RRESP   (s_axi_rresp),
        .S_AXI_RVALID  (s_axi_rvalid),
        .S_AXI_RREADY  (s_axi_rready)
    );

    // --- 4. AXI Lite Master Tasks ---
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;
            wait(s_axi_awready && s_axi_wready);
            @(posedge clk);
            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;
            wait(s_axi_bvalid);
            @(posedge clk);
            s_axi_bready  <= 1'b0;
        end
    endtask

    task axi_read(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;
            s_axi_rready  <= 1'b1;
            wait(s_axi_arready);
            @(posedge clk);
            s_axi_arvalid <= 1'b0;
            wait(s_axi_rvalid);
            data = s_axi_rdata;
            @(posedge clk);
            s_axi_rready  <= 1'b0;
        end
    endtask

    // --- 5. Main Test & Throughput Logic ---
    initial begin
        // Reset sequence
        rst_n = 0;
        s_axi_awvalid = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_arvalid = 0; s_axi_rready = 0;
        #(CLK_PERIOD * 10) rst_n = 1;
        s_axi_wstrb = 4'b1111;
        
        $display("--- Initializing AES Data ---");
        // Load Key (Modify addresses to match your slv_reg map)
        axi_write(32'h04, 32'h2B7E1516); 
        axi_write(32'h08, 32'h28AED2A6);
        axi_write(32'h0C, 32'hABF71588);
        axi_write(32'h10, 32'h09CF4F3C);

        // Load Plaintext
        axi_write(32'h14, 32'h6BC1BEE2);
        axi_write(32'h18, 32'h2E409F96);
        axi_write(32'h1C, 32'hE93D7E11);
        axi_write(32'h20, 32'h7393E722);

        // Trigger START (Write 1 to Control Reg at 0x00)
        axi_write(32'h00, 32'h00000001);

        // POLL STATUS (Assume Done bit is Bit 1 of Reg 0x00)
        status_reg = 0;
        while (!(status_reg & 32'h00000002)) begin
            axi_read(32'h04, status_reg);
            // Optional: small delay between polls to mimic real CPU
            #(CLK_PERIOD * 2); 
        end
        $finish;
    end

endmodule
