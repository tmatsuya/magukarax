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

`ifdef NO
  output [63:0] xgmii_2_txd,
  output [7:0]  xgmii_2_txc,
  input  [63:0] xgmii_2_rxd,
  input  [7:0]  xgmii_2_rxc,

  output [63:0] xgmii_3_txd,
  output [7:0]  xgmii_3_txc,
  input  [63:0] xgmii_3_rxd,
  input  [7:0]  xgmii_3_rxc,
`endif

`ifdef NO
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
`endif

  output reg [31:0] global_counter
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
// Transmitte logic
//-----------------------------------
reg [31:0] tx_counter;
reg [63:0] txd;
reg [7:0] txc;

//-----------------------------------
// CRC logic
//-----------------------------------
reg crc_init = 1'b0;
assign crc_data_en = ~crc_init;
wire [31:0] crc_out, crc_out2;
assign crc_out2 = ~{ crc_out[24],crc_out[25],crc_out[26],crc_out[27],crc_out[28],crc_out[29],crc_out[30],crc_out[31], crc_out[16],crc_out[17],crc_out[18],crc_out[19],crc_out[20],crc_out[21],crc_out[22],crc_out[23], crc_out[ 8],crc_out[ 9],crc_out[10],crc_out[11],crc_out[12],crc_out[13],crc_out[14],crc_out[15], crc_out[ 0],crc_out[ 1],crc_out[ 2],crc_out[ 3],crc_out[ 4],crc_out[ 5],crc_out[ 6],crc_out[ 7] };

crc32_d64 crc32_d64_inst (
  .rst(crc_init),
  .clk(sys_clk),
  .crc_en(crc_data_en),
  .data_in({
txd[00],txd[01],txd[02],txd[03],txd[04],txd[05],txd[06],txd[07],txd[08],txd[09],
txd[10],txd[11],txd[12],txd[13],txd[14],txd[15],txd[16],txd[17],txd[18],txd[19],
txd[20],txd[21],txd[22],txd[23],txd[24],txd[25],txd[26],txd[27],txd[28],txd[29],
txd[30],txd[31],txd[32],txd[33],txd[34],txd[35],txd[36],txd[37],txd[38],txd[39],
txd[40],txd[41],txd[42],txd[43],txd[44],txd[45],txd[46],txd[47],txd[48],txd[49],
txd[50],txd[51],txd[52],txd[53],txd[54],txd[55],txd[56],txd[57],txd[58],txd[59],
txd[60],txd[61],txd[62],txd[63]
}),	// 64bit
  .crc_out(crc_out)	// 32bit
);

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


always @(posedge sys_clk) begin
        if ( sys_rst ) begin
		crc_init <= 1'b0;
                tx_counter <= 32'h0;
                txd <= 64'h0707070707070707;
                txc <= 8'hff;
        end else begin
                tx_counter <= tx_counter + 32'h8;
                case (tx_counter[15:0] )
                        16'h00: begin
				{txc, txd} <= {8'h01, 64'hd5_55_55_55_55_55_55_fb};
				crc_init <= 1'b1;
			end
                        16'h08: begin
				{txc, txd} <= {8'h00, 64'hde_a0_00_d6_7b_1d_25_11};
				crc_init <= 1'b0;
			end
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
//                      16'h68: {txc, txd} <= {8'hfe, 64'h07_07_fd_ba_fc_4f_47_37};
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
