//`timescale 1ns / 1ps
`include "../rtl/setup.v"

module l2switch # (
	parameter MaxPort = 2'h1
) (
	input	 sys_rst,
	input	 sys_clk,

	input	 xgemac_clk_156,

	// XGMII interfaces for 4 MACs
	output [63:0] xgmii_0_txd,
	output  [7:0] xgmii_0_txc,
	input  [63:0] xgmii_0_rxd,
	input   [7:0] xgmii_0_rxc,
	input   [7:0] xphy_0_status,

	output [63:0] xgmii_1_txd,
	output  [7:0] xgmii_1_txc,
	input  [63:0] xgmii_1_rxd,
	input   [7:0] xgmii_1_rxc,
	input   [7:0] xphy_1_status,

`ifdef ENABLE_PHY2
	output [63:0] xgmii_2_txd,
	output  [7:0] xgmii_2_txc,
	input  [63:0] xgmii_2_rxd,
	input   [7:0] xgmii_2_rxc,
	input   [7:0] xphy_2_status,
`endif

`ifdef ENABLE_PHY3
	output [63:0] xgmii_3_txd,
	output  [7:0] xgmii_3_txc,
	input  [63:0] xgmii_3_rxd,
	input   [7:0] xgmii_3_rxc,
	input   [7:0] xphy_3_status,
`endif

	// ---- BUTTON
	input	 button_n,
	input	 button_s,
	input	 button_w,
	input	 button_e,
	input	 button_c,
	// ---- DIP SW
	input   [3:0] dipsw,		
	// ---- LED
	output  [7:0] led		   

);

//-----------------------------------
// RX0,RX1,RX2,RX3_PHYQ FIFO
//-----------------------------------
//
wire [71:0] rx0_phyq_din, rx0_phyq_dout;
wire rx0_phyq_full, rx0_phyq_wr_en;
wire rx0_phyq_empty, rx0_phyq_rd_en;

wire [71:0] rx1_phyq_din, rx1_phyq_dout;
wire rx1_phyq_full, rx1_phyq_wr_en;
wire rx1_phyq_empty, rx1_phyq_rd_en;

wire [71:0] rx2_phyq_din, rx2_phyq_dout;
wire rx2_phyq_full, rx2_phyq_wr_en;
wire rx2_phyq_empty, rx2_phyq_rd_en;

wire [71:0] rx3_phyq_din, rx3_phyq_dout;
wire rx3_phyq_full, rx3_phyq_wr_en;
wire rx3_phyq_empty, rx3_phyq_rd_en;

`ifdef SIMULATION
sfifo # (
	.DATA_WIDTH(72),
	.ADDR_WIDTH(10)
) rx0fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx0_phyq_din),
	.full(rx0_phyq_full),
	.wr_cs(rx0_phyq_wr_en),
	.wr_en(rx0_phyq_wr_en),

	.dout(rx0_phyq_dout),
	.empty(rx0_phyq_empty),
	.rd_cs(rx0_phyq_rd_en),
	.rd_en(rx0_phyq_rd_en),

	.data_count()
);
sfifo # (
	.DATA_WIDTH(72),
	.ADDR_WIDTH(10)
) rx1fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx1_phyq_din),
	.full(rx1_phyq_full),
	.wr_cs(rx1_phyq_wr_en),
	.wr_en(rx1_phyq_wr_en),

	.dout(rx1_phyq_dout),
	.empty(rx1_phyq_empty),
	.rd_cs(rx1_phyq_rd_en),

	.data_count()
);
`ifdef ENABLE_PHY2
sfifo # (
	.DATA_WIDTH(72),
	.ADDR_WIDTH(10)
) rx2fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx2_phyq_din),
	.full(rx2_phyq_full),
	.wr_cs(rx2_phyq_wr_en),
	.wr_en(rx2_phyq_wr_en),

	.dout(rx2_phyq_dout),
	.empty(rx2_phyq_empty),
	.rd_cs(rx2_phyq_rd_en),

	.data_count()
);
`endif
`ifdef ENABLE_PHY3
sfifo # (
	.DATA_WIDTH(72),
	.ADDR_WIDTH(10)
) rx3fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx3_phyq_din),
	.full(rx3_phyq_full),
	.wr_cs(rx3_phyq_wr_en),
	.wr_en(rx3_phyq_wr_en),

	.dout(rx3_phyq_dout),
	.empty(rx3_phyq_empty),
	.rd_cs(rx3_phyq_rd_en),

	.data_count()
);
`endif
`else
sfifo72_10 rx0fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx0_phyq_din),
	.full(rx0_phyq_full),
	.wr_en(rx0_phyq_wr_en),

	.dout(rx0_phyq_dout),
	.empty(rx0_phyq_empty),
	.rd_en(rx0_phyq_rd_en),

	.data_count()
);
sfifo72_10 rx1fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx1_phyq_din),
	.full(rx1_phyq_full),
	.wr_en(rx1_phyq_wr_en),

	.dout(rx1_phyq_dout),
	.empty(rx1_phyq_empty),
	.rd_en(rx1_phyq_rd_en),

	.data_count()
);
`ifdef ENABLE_PHY2
sfifo72_10 rx2fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx2_phyq_din),
	.full(rx2_phyq_full),
	.wr_en(rx2_phyq_wr_en),

	.dout(rx2_phyq_dout),
	.empty(rx2_phyq_empty),
	.rd_en(rx2_phyq_rd_en),

	.data_count()
);
`endif
`ifdef ENABLE_PHY3
sfifo72_10 rx3fifo (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(rx3_phyq_din),
	.full(rx3_phyq_full),
	.wr_en(rx3_phyq_wr_en),

	.dout(rx3_phyq_dout),
	.empty(rx3_phyq_empty),
	.rd_en(rx3_phyq_rd_en),

	.data_count()
);
`endif
`endif

//-----------------------------------
// XGMII2FIFO72 module
//-----------------------------------
xgmii2fifo72 # (
	.Gap(4'h2)
) rx0xgmii2fifo (
	.sys_rst(sys_rst),

	.xgmii_rx_clk(xgemac_clk_156),
	.xgmii_rxd({xgmii_0_rxc,xgmii_0_rxd}),

	.din(rx0_phyq_din),
	.full(rx0_phyq_full),
	.wr_en(rx0_phyq_wr_en),
	.wr_clk()
);
xgmii2fifo72 # (
	.Gap(4'h2)
) rx1xgmii2fifo (
	.sys_rst(sys_rst),

	.xgmii_rx_clk(xgemac_clk_156),
	.xgmii_rxd({xgmii_1_rxc,xgmii_1_rxd}),

	.din(rx1_phyq_din),
	.full(rx1_phyq_full),
	.wr_en(rx1_phyq_wr_en),
	.wr_clk()
);
`ifdef ENABLE_PHY2
xgmii2fifo72 # (
	.Gap(4'h2)
) rx2xgmii2fifo (
	.sys_rst(sys_rst),

	.xgmii_rx_clk(xgemac_clk_156),
	.xgmii_rxd({xgmii_2_rxc,xgmii_2_rxd}),

	.din(rx2_phyq_din),
	.full(rx2_phyq_full),
	.wr_en(rx2_phyq_wr_en),
	.wr_clk()
);
`endif
`ifdef ENABLE_PHY3
xgmii2fifo72 # (
	.Gap(4'h2)
) rx3xgmii2fifo (
	.sys_rst(sys_rst),

	.xgmii_rx_clk(xgemac_clk_156),
	.xgmii_rxd({xgmii_3_rxc,xgmii_3_rxd}),

	.din(rx3_phyq_din),
	.full(rx3_phyq_full),
	.wr_en(rx3_phyq_wr_en),
	.wr_clk()
);
`endif

//-----------------------------------
// FIFO72TOXGMII module
//-----------------------------------
fifo72toxgmii tx0fifo2gmii (
	.sys_rst(sys_rst),

	.dout(rx1_phyq_dout),
	.empty(rx1_phyq_empty),
	.rd_en(rx1_phyq_rd_en),
	.rd_clk(),

	.xgmii_tx_clk(xgemac_clk_156),
	.xgmii_txd({xgmii_0_txc,xgmii_0_txd})
);
fifo72toxgmii tx1fifo2gmii (
	.sys_rst(sys_rst),

	.dout(rx0_phyq_dout),
	.empty(rx0_phyq_empty),
	.rd_en(rx0_phyq_rd_en),
	.rd_clk(),

	.xgmii_tx_clk(xgemac_clk_156),
	.xgmii_txd({xgmii_1_txc,xgmii_1_txd})
);
`ifdef ENABLE_PHY2
fifo72toxgmii tx2fifo2gmii (
	.sys_rst(sys_rst),

	.dout(),
	.empty(1'b1),
	.rd_en(),
	.rd_clk(),

	.xgmii_tx_clk(xgemac_clk_156),
	.xgmii_txd({xgmii_2_txc,xgmii_2_txd})
);
`endif
`ifdef ENABLE_PHY3
fifo72toxgmii tx3fifo2gmii (
	.sys_rst(sys_rst),

	.dout(),
	.empty(1'b1),
	.rd_en(),
	.rd_clk(),

	.xgmii_tx_clk(xgemac_clk_156),
	.xgmii_txd({xgmii_3_txc,xgmii_3_txd})
);
`endif

// XGMII control characters
// 07: Idle, FB:Start FD:Terminate FE:ERROR
//
`ifdef NO
reg [11:0] rx_counter = 12'h0;
reg [7:0] led_out = 8'h0;
always @(posedge xgemac_clk_156) begin
	if (sys_rst == 1'b1) begin
		rx_counter <= 12'h0;
		led_out <= 8'h0;
	end else begin
		if (xgmii_0_rxc != 8'hff) begin
			rx_counter <= rx_counter + 12'h8;
			if (rx_counter[11:3] == {8'h0, dipsw[3]}) begin
				case (dipsw[2:0] )
					3'h0: led_out <= xgmii_0_rxd[ 7: 0];
					3'h1: led_out <= xgmii_0_rxd[15: 8];
					3'h2: led_out <= xgmii_0_rxd[23:16];
					3'h3: led_out <= xgmii_0_rxd[31:24];
					3'h4: led_out <= xgmii_0_rxd[39:32];
					3'h5: led_out <= xgmii_0_rxd[47:40];
					3'h6: led_out <= xgmii_0_rxd[55:48];
					3'h7: led_out <= xgmii_0_rxd[63:56];
				endcase
			end
		end else begin
			rx_counter <= 12'h0;
		end
	end
end

reg [15:0] tx_counter = 16'h0;
reg [63:0] txd;
reg [7:0] txc;
always @(posedge xgemac_clk_156) begin
	if (sys_rst == 1'b1) begin
		tx_counter <= 16'h0;
		txd <= 64'h0707070707070707;
		txc <= 8'hff;
	end else begin
		tx_counter <= tx_counter + 16'h8;
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
			default:{txc, txd} <= {8'hff, 64'h07_07_07_07_07_07_07_07};
		endcase
	end
end

assign xgmii_0_txd = txd;
assign xgmii_0_txc = txc;
assign xgmii_1_txd = txd;
assign xgmii_1_txc = txc;
`ifdef ENABLE_PHY2
assign xgmii_2_txd = txd;
assign xgmii_2_txc = txc;
`endif
`ifdef ENABLE_PHY3
assign xgmii_3_txd = txd;
assign xgmii_3_txc = txc;
`endif

assign led[7:0] = button_e ? {4'b0, xphy_3_status[0], xphy_2_status[0], xphy_1_status[0], xphy_0_status[0]} : led_out;
`endif

assign led[7:4] = 4'h0;
assign led[1:0] = {xphy_1_status[0], xphy_0_status[0]};
`ifdef ENABLE_PHY2
assign led[2] = xphy_1_status[2];
`endif
`ifdef ENABLE_PHY3
assign led[3] = xphy_1_status[3];
`endif

endmodule
