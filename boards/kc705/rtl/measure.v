`timescale 1ns / 1ps
//`define DEBUG

module measure (
  input         sys_rst,
  input         sys_clk,

  // XGMII interfaces for 4 MACs
  output [63:0] xgmii_0_txd,
  output [7:0]  xgmii_0_txc,
  input  [63:0] xgmii_0_rxd,
  input  [7:0]  xgmii_0_rxc,

  output [63:0] xgmii_1_txd,
  output [7:0]  xgmii_1_txc,
  input  [63:0] xgmii_1_rxd,
  input  [7:0]  xgmii_1_rxc,

  output [63:0] xgmii_2_txd,
  output [7:0]  xgmii_2_txc,
  input  [63:0] xgmii_2_rxd,
  input  [7:0]  xgmii_2_rxc,

  output [63:0] xgmii_3_txd,
  output [7:0]  xgmii_3_txc,
  input  [63:0] xgmii_3_rxd,
  input  [7:0]  xgmii_3_rxc,

  // PCI user registers
  input         tx0_enable,
  input         tx0_ipv6,
  input         tx0_fullroute,
  input         tx0_req_arp,
  input [15:0]  tx0_frame_len,
  input [31:0]  tx0_inter_frame_gap,
  input [31:0]  tx0_ipv4_srcip,
  input [47:0]  tx0_src_mac,
  input [31:0]  tx0_ipv4_gwip,
  input [127:0]  tx0_ipv6_srcip,
  input [127:0]  tx0_ipv6_dstip,
  output reg [47:0] tx0_dst_mac,
  input [31:0]  tx0_ipv4_dstip,
  output reg [31:0] tx0_pps,
  output reg [31:0] tx0_throughput,
  output [31:0] tx0_ipv4_ip,

  output [31:0] rx1_pps,
  output [31:0] rx1_throughput,
  output [23:0] rx1_latency,
  output [31:0] rx1_ipv4_ip,

  output [31:0] rx2_pps,
  output [31:0] rx2_throughput,
  output [23:0] rx2_latency,
  output [31:0] rx2_ipv4_ip,

  output [31:0] rx3_pps,
  output [31:0] rx3_throughput,
  output [23:0] rx3_latency,
  output [31:0] rx3_ipv4_ip,

  output reg [31:0] global_counter,
  output [31:0] count_2976_latency
);

//-----------------------------------
// One second clock
//-----------------------------------
reg sec_oneshot;
reg [27:0] sec_counter;
always @(posedge sys_clk) begin
  if (sys_rst) begin
    sec_counter <= 28'd156250000;
    sec_oneshot <= 1'b0;
  end else begin
    if (sec_counter == 27'd0) begin
      sec_counter <= 28'd156250000;
      sec_oneshot <= 1'b1;
    end else begin
      sec_counter <= sec_counter - 28'd1;
      sec_oneshot <= 1'b0;
    end
  end
end

//-----------------------------------
// CRC logic
//-----------------------------------
crc32_d64 crc32_d64_inst (
  .rst(sys_rst),
  .clk(sys_clk),
  .crc_en(),
  .data_in(),	// 64bit
  .crc_out()	// 32bit
);

//-----------------------------------
// Transmitte logic
//-----------------------------------
reg [15:0] tx_count = 16'h0;
reg [7:0] tx_data;
reg tx_en = 1'b0;

//-----------------------------------
// CRC
//-----------------------------------
assign crc_init = (tx_count ==  16'h08);
wire [31:0] crc_out;
reg crc_rd;
assign crc_data_en = ~crc_rd;
//crc_gen crc_inst (
//  .Reset(sys_rst),
//  .Clk(sys_clk),
//  .Init(crc_init),
//  .Frame_data(tx_data),
//  .Data_en(crc_data_en),
//  .CRC_rd(crc_rd),
//  .CRC_end(),
//  .CRC_out(crc_out)
//); 

//-----------------------------------
// Global counter
//-----------------------------------
always @(posedge sys_clk) begin
  if (sys_rst) begin
    global_counter <= 32'h0;
  end else begin
    global_counter <= global_counter + 32'h1;
  end
end


reg [31:0] tx_counter;
reg [63:0] txd;
reg [7:0] txc;
always @(posedge sys_clk) begin
        if ( sys_rst ) begin
                tx_counter <= 32'h0;
                txd <= 64'h0707070707070707;
                txc <= 8'hff;
        end else begin
                tx_counter <= tx_counter + 32'h8;
                case (tx_counter[15:0] )
                        16'h00: {txc, txd} <= {8'h01, 64'hd5_55_55_55_55_55_55_fb};
                        16'h08: {txc, txd} <= {8'h00, 64'hde_a0_00_d6_7b_1d_25_11};
                        16'h10: {txc, txd} <= {8'h00, 64'h00_00_45_00_08_e8_07_1c};
                        16'h18: {txc, txd} <= {8'h00, 64'h44_01_40_00_00_99_f8_54};
                        16'h20: {txc, txd} <= {8'h00, 64'h16_00_0a_69_15_00_0a_9d};
                        16'h28: {txc, txd} <= {8'h00, 64'h00_07_b8_45_d5_00_08_64};
                        16'h30: {txc, txd} <= {8'h00, 64'hab_05_00_06_84_ac_4f_07};
                        16'h38: {txc, txd} <= {8'h00, 64'h0e_0d_0c_0b_0a_09_08_f0};
                        16'h40: {txc, txd} <= {8'h00, 64'h16_15_14_13_12_11_10_0f};
                        16'h48: {txc, txd} <= {8'h00, 64'h1e_1d_1c_1b_1a_19_18_17};
                        16'h50: {txc, txd} <= {8'h00, 64'h26_25_24_23_22_21_20_1f};
                        16'h58: {txc, txd} <= {8'h00, 64'h2e_2d_2c_2b_2a_29_28_27};
                        16'h60: {txc, txd} <= {8'h00, 64'h36_35_34_33_32_31_30_2f};
                        16'h68: {txc, txd} <= {8'he0, 64'h07_07_fd_ba_fc_4f_47_37};
                        default: begin
                                {txc, txd} <= {8'hff, 64'h07_07_07_07_07_07_07_07};
                        end
                endcase
        end
end

assign xgmii_0_txd = txd;
assign xgmii_0_txc = txc;
assign xgmii_1_txd = txd;
assign xgmii_1_txc = txc;

endmodule
