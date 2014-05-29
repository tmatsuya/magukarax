`timescale 1ns / 1ps
`include "../rtl/setup.v"
//`define DEBUG

module measure (
	input         sys_rst,
	input         sys_clk,

	// XGMII interfaces for 4 MACs
	output [63:0] xgmii_0_txd,
	output [7:0] xgmii_0_txc,
	input [63:0] xgmii_0_rxd,
	input [7:0] xgmii_0_rxc,

	output [63:0] xgmii_1_txd,
	output [7:0] xgmii_1_txc,
	input [63:0] xgmii_1_rxd,
	input [7:0] xgmii_1_rxc,

`ifdef NO
	output [63:0] xgmii_2_txd,
	output [7:0] xgmii_2_txc,
	input [63:0] xgmii_2_rxd,
	input [7:0] xgmii_2_rxc,

	output [63:0] xgmii_3_txd,
	output [7:0] xgmii_3_txc,
	input [63:0] xgmii_3_rxd,
	input [7:0] xgmii_3_rxc,
`endif

	// PCI user registers
	input tx0_enable,
	input tx0_ipv6,
	input tx0_fullroute,
	input tx0_req_arp,
	input [15:0] tx0_frame_len,
	input [31:0] tx0_inter_frame_gap,
	input [31:0] tx0_ipv4_srcip,
	input [47:0] tx0_src_mac,
	input [31:0] tx0_ipv4_gwip,
	input [127:0] tx0_ipv6_srcip,
	input [127:0] tx0_ipv6_dstip,
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
// Transmitte logic
//-----------------------------------
reg [31:0] tx_counter;
reg [63:0] txd, txd2;
reg [7:0] txc, txc2;

//-----------------------------------
// CRC logic
//-----------------------------------
reg crc_init = 1'b0;
reg crc_rewrite = 1'b0;
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

//-----------------------------------
// scenario parameter
//-----------------------------------
wire [39:0] magic_code       = `MAGIC_CODE;
reg [16:0] ipv4_id           = 16'h0;
reg [7:0]  ipv4_ttl          = 8'h40;      // IPv4: default TTL value (default: 64)
reg [31:0] pps;
reg [31:0] throughput;
reg [23:0] full_ipv4;
reg [23:0] ip_sum;
reg [15:0] arp_wait_count;

wire [15:0] frame_crc1_count = tx0_frame_len + 16'h4;
wire [15:0] frame_crc2_count = tx0_frame_len + 16'h5;
wire [15:0] frame_crc3_count = tx0_frame_len + 16'h6;
wire [15:0] frame_crc4_count = tx0_frame_len + 16'h7;
wire [15:0] frame_end_count  = tx0_frame_len + 16'h8;

reg [2:0] tx_state;
reg [31:0] gap_count;
parameter TX_REQ_ARP     = 3'h0;  // Send ARP request
parameter TX_WAIT_ARPREP = 3'h1;  // Wait ARP reply
parameter TX_V4_SEND     = 3'h2;  // IPv4 Payload
parameter TX_V6_SEND     = 3'h3;  // IPv6 Payload
parameter TX_GAP         = 3'h4;  // Inter Frame Gap

wire [31:0] ipv4_dstip = (tx0_fullroute == 1'b0) ? tx0_ipv4_dstip[31:0] : {full_ipv4[23:0],8'h1};  // IPv4: Destination Address
wire [15:0] tx0_udp_len = tx0_frame_len - 16'h26;  // UDP Length
wire [15:0] tx0_ip_len  = tx0_frame_len - 16'd18;  // IP Length (Frame Len - FCS Len - EtherFrame Len

reg [23:0] tmp_counter;

always @(posedge sys_clk) begin
        if ( sys_rst ) begin
		crc_init <= 1'b0;
		crc_rewrite <= 1'b0;
                tx_counter <= 32'h0;
		tmp_counter <= 24'h0;
                txd <= 64'h0707070707070707;
                txc <= 8'hff;
  		tx0_dst_mac <= 48'hffffffffffff;
        end else begin
		crc_rewrite <= 1'b0;
		txc2 <= txc;
		if (crc_rewrite == 1'b0)
			txd2 <= txd;
		else
			txd2 <= {txd[63:32], crc_out2[7:0], crc_out2[15:8], crc_out2[23:16], crc_out2[31:24]};
                tx_counter <= tx_counter + 32'h8;
                case (tx_counter[15:0] )
                        16'h00: begin
				{txc, txd} <= {8'h01, 64'hd5_55_55_55_55_55_55_fb};
				ip_sum <= 16'h4500 + {4'h0,tx0_ip_len[11:0]} + ipv4_id[15:0] + {ipv4_ttl[7:0],8'h11} + tx0_ipv4_srcip[31:16] + tx0_ipv4_srcip[15:0] + ipv4_dstip[31:16] + ipv4_dstip[15:0];
				crc_init <= 1'b1;
			end
                        16'h08: begin
				{txc, txd} <= {8'h00, tx0_src_mac[39:32], tx0_src_mac[47:40], tx0_dst_mac[7:0], tx0_dst_mac[15:8], tx0_dst_mac[23:16], tx0_dst_mac[31:24], tx0_dst_mac[39:32], tx0_dst_mac[47:40]};
				ip_sum <= ~(ip_sum[15:0] + ip_sum[23:16]);

				crc_init <= 1'b0;
			end
                        16'h10: {txc, txd} <= {8'h00, 32'h00_45_00_08, tx0_src_mac[7:0], tx0_src_mac[15:8], tx0_src_mac[23:16], tx0_src_mac[31:24]};
                        16'h18: {txc, txd} <= {8'h00, 8'h11, ipv4_ttl[7:0], 16'h00, ipv4_id[7:0], ipv4_id[15:8], tx0_ip_len[7:0], 4'h0, tx0_ip_len[11:8]};
                        16'h20: {txc, txd} <= {8'h00, ipv4_dstip[23:16], ipv4_dstip[31:24], tx0_ipv4_srcip[7:0], tx0_ipv4_srcip[15:8], tx0_ipv4_srcip[23:16], tx0_ipv4_srcip[31:24], ip_sum[7:0], ip_sum[15:8]};
                        16'h28: {txc, txd} <= {8'h00, tx0_udp_len[7:0], 4'h0, tx0_udp_len[11:8], 32'h5e_0d_5e_0d, ipv4_dstip[7:0], ipv4_dstip[15:8]};
                        16'h30: begin
				{txc, txd} <= {8'h00, global_counter[31:24], magic_code[7:0], magic_code[15:8], magic_code[23:16], magic_code[31:24], magic_code[39:32], 16'h00_00};
				tmp_counter[23:0] <= global_counter[23:0];
			end
                        16'h38: {txc, txd} <= {8'h00, 40'h00_00_00_00_00, tmp_counter[7:0], tmp_counter[15:8], tmp_counter[23:16]};
                        16'h40: {txc, txd} <= {8'h00, 64'h00_00_00_00_00_00_00_00};
                        16'h48: begin
				{txc, txd} <= {8'hf0, 32'h07_07_07_fd, crc_out2[7:0], crc_out2[15:8], crc_out2[23:16], crc_out2[31:24]};
				crc_rewrite <= 1'b1;
			end
                        default: begin
                                {txc, txd} <= {8'hff, 64'h07_07_07_07_07_07_07_07};
                        end
                endcase
        end
end

assign xgmii_0_txd = txd2;
assign xgmii_0_txc = txc2;

//-----------------------------------
// RX#1 Recive port logic
//-----------------------------------
measure_core # (
	.Int_ipv4_addr({8'd10, 8'd0, 8'd21, 8'd105}),
	.Int_ipv6_addr(128'h3776_0000_0000_0021_0000_0000_0000_0105),
	.Int_mac_addr(48'h003776_000101)
) measure_phy1 (
	.sys_rst(sys_rst),
	.sys_clk(sys_clk),
	.pci_clk(pci_clk),
	.sec_oneshot(sec_oneshot),
	.global_counter(global_counter),

	.xgmii_txd(xgmii_1_txd),
	.xgmii_txc(xgmii_1_txc),
	.xgmii_rxd(xgmii_1_rxd),
	.xgmii_rxc(xgmii_1_rxc),

	.rx_pps(rx1_pps),
	.rx_throughput(rx1_throughput),
	.rx_latency(rx1_latency),
	.rx_ipv4_ip(rx1_ipv4_ip),
	.tx_ipv6(tx_ipv6),

	.count_2976_latency(count_2976_latency)
);

endmodule
