// =============================================================================
// Module  : AES_AXI_Lite_slave
// Brief   : AXI4-Lite slave wrapping an AES-128 enc/dec engine.
//
// Register Map (byte address, 32-bit words):
//   0x00–0x0C : KEY[127:0]         write
//   0x10–0x1C : PLAINTEXT[127:0]   write
//   0x20–0x2C : CIPHERTEXT[127:0]  read-only (written by AES core)
//   0x30      : CTRL  [0]=start  [1]=enc_dec_en  [2]=key_en_in
//   0x34      : STATUS [0]=done
//   0x38–0x3C : Reserved
//
// Write priority (single always_ff to avoid multiple drivers):
//   1. aes_done        → ciphertext + STATUS[0]=1
//   2. aes_start_pulse → STATUS[0]=0  (auto-clear for next op)
//   3. AXI write       → key/plaintext/ctrl/status only; output regs protected
//
// Target  : Xilinx Artix-7 (Basys 3 / PYNQ-Z2), Vivado 2024.x
// Author  : Kanishk Jaiswal
// =============================================================================

module AES_AXI_Lite_slave #(
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer C_S_AXI_ADDR_WIDTH = 6
)(
  input logic                                   S_AXI_ACLK,
  input logic                                   S_AXI_ARESETN,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]         S_AXI_AWADDR,
  input  logic                                   S_AXI_AWVALID,
  output logic                                   S_AXI_AWREADY,

  input  logic [C_S_AXI_DATA_WIDTH-1:0]         S_AXI_WDATA,
  input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0]     S_AXI_WSTRB,
  input  logic                                   S_AXI_WVALID,
  output logic                                   S_AXI_WREADY,

  output logic [1:0]                             S_AXI_BRESP,
  output logic                                   S_AXI_BVALID,
  input  logic                                   S_AXI_BREADY,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]         S_AXI_ARADDR,
  input  logic                                   S_AXI_ARVALID,
  output logic                                   S_AXI_ARREADY,

  output logic [C_S_AXI_DATA_WIDTH-1:0]         S_AXI_RDATA,
  output logic [1:0]                             S_AXI_RRESP,
  output logic                                   S_AXI_RVALID,
  input  logic                                   S_AXI_RREADY
);

  localparam DW       = C_S_AXI_DATA_WIDTH;
  localparam AW       = C_S_AXI_ADDR_WIDTH - 2;
  localparam ADDR_LSB = 2; // log2(DW/8); strips byte-lane bits to get word index

  logic axi_awready, axi_wready, axi_bvalid;
  logic axi_arready, axi_rvalid;
  logic [DW-1:0] axi_rdata;

  assign S_AXI_AWREADY = axi_awready;
  assign S_AXI_WREADY  = axi_wready;
  assign S_AXI_BRESP   = 2'b00; // Always OKAY
  assign S_AXI_BVALID  = axi_bvalid;
  assign S_AXI_ARREADY = axi_arready;
  assign S_AXI_RDATA   = axi_rdata;
  assign S_AXI_RRESP   = 2'b00; // Always OKAY
  assign S_AXI_RVALID  = axi_rvalid;

  // Unified register array — single array for all AXI and AES I/O avoids
  // multiple-driver conflicts from separate write/read/DUT output paths.
  logic [DW-1:0] slv_mem [0:15];

  initial begin
    for (int i = 0; i < 16; i++) slv_mem[i] = 0; // Sim only; reset handles hardware init
  end

  logic [127:0] aes_key, aes_plaintext, aes_ciphertext;
  logic         aes_done;

  assign aes_key       = {slv_mem[3], slv_mem[2], slv_mem[1], slv_mem[0]};
  assign aes_plaintext = {slv_mem[7], slv_mem[6], slv_mem[5], slv_mem[4]};

  // Edge-detect on CTRL[0]: AES core needs a single-cycle pulse.
  // Directly wiring CTRL[0] would re-trigger if master writes the register again.
  logic start_bit_q, aes_start_pulse;
  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      start_bit_q     <= 1'b0;
      aes_start_pulse <= 1'b0;
    end else begin
      start_bit_q     <= slv_mem[12][0];
      aes_start_pulse <= slv_mem[12][0] && !start_bit_q; // rising-edge detect
    end
  end

  logic aes_enc_dec_en, aes_key_en_in;
  assign aes_enc_dec_en = slv_mem[12][1];
  assign aes_key_en_in  = slv_mem[12][2];

  AES_encryption_decryption_top aes_inst (
    .clk        (S_AXI_ACLK),
    .rst        (!S_AXI_ARESETN), // Core is active-high reset
    .start      (aes_start_pulse),
    .enc_dec_en (aes_enc_dec_en),
    .key_en_in  (aes_key_en_in),
    .key        (aes_key),
    .text_input (aes_plaintext),
    .text_output(aes_ciphertext),
    .done       (aes_done)
  );

  // ---------------------------------------------------------------------------
  // Read Channel
  // ---------------------------------------------------------------------------
  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN)                       axi_rvalid <= 1'b0;
    else if (S_AXI_ARVALID && S_AXI_ARREADY) axi_rvalid <= 1'b1;
    else if (S_AXI_RVALID  && S_AXI_RREADY)  axi_rvalid <= 1'b0;
  end

  // Block new read address while current RDATA transfer is in progress
  always_comb axi_arready = S_AXI_RVALID ? 1'b0 : 1'b1;

  always_ff @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)                       axi_rdata <= '0;
    else if (S_AXI_ARVALID && S_AXI_ARREADY) axi_rdata <= slv_mem[S_AXI_ARADDR[AW+ADDR_LSB-1 : ADDR_LSB]];

  // ---------------------------------------------------------------------------
  // Write Channel
  // ---------------------------------------------------------------------------

  // Back-pressure: block new writes until master acknowledges current response
  always_comb begin
    if (S_AXI_BVALID) begin
      axi_awready = 1'b0;
      axi_wready  = 1'b0;
    end else begin
      axi_awready = 1'b1;
      axi_wready  = 1'b1;
    end
  end

  wire [AW-1:0] wr_idx   = S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH-1 : ADDR_LSB];
  wire          write_en = S_AXI_AWVALID && S_AXI_AWREADY && S_AXI_WVALID && S_AXI_WREADY;

  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN)    axi_bvalid <= 1'b0;
    else if (write_en)     axi_bvalid <= 1'b1;
    else if (S_AXI_BREADY) axi_bvalid <= 1'b0;
  end

  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      for (int i = 0; i < 16; i++) slv_mem[i] <= 32'h0;
    end else begin

      if (aes_done) begin
        // AES core wins priority — overrides any simultaneous AXI write
        slv_mem[8]  <= aes_ciphertext[31:0];
        slv_mem[9]  <= aes_ciphertext[63:32];
        slv_mem[10] <= aes_ciphertext[95:64];
        slv_mem[11] <= aes_ciphertext[127:96];
        slv_mem[13] <= 32'h0000_0001; // STATUS[0] = done

      end else if (aes_start_pulse) begin
        slv_mem[13] <= 32'h0; // Auto-clear done even if software forgets

      end else if (write_en) begin
        // Protect output regs [8–11] and reserved [14–15] from AXI writes
        if (wr_idx <= 7 || wr_idx == 12 || wr_idx == 13) begin
          for (int i = 0; i < (DW/8); i++) begin
            if (S_AXI_WSTRB[i])
              slv_mem[wr_idx][(i*8) +: 8] <= S_AXI_WDATA[(i*8) +: 8];
          end
        end
      end

    end
  end

endmodule
