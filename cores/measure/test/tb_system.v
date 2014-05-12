`timescale 1ps / 1ps
`define SIMULATION
//`include "../rtl/setup.v"
module tb_system();

`ifndef VERILATOR
/* 125MHz system clock */
reg sys_clk, sys_rst;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

// System
// Phy
wire [63:0] xgmii_0_txd;
wire [7:0] xgmii_0_txc;
reg [63:0] xgmii_0_rxd;
reg [7:0] xgmii_0_rxc;
reg [7:0] xphy_0_status;
wire [63:0] xgmii_1_txd;
wire [7:0] xgmii_1_txc;
reg [63:0] xgmii_1_rxd;
reg [7:0] xgmii_1_rxc;
reg [7:0] xphy_1_status;
// ---- BUTTON
reg button_n;
reg button_s;
reg button_w;
reg button_e;
reg button_c;
// ---- DIP SW
reg [3:0] dipsw;
// ---- LED
wire [7:0] led;


measure measure_inst (
	.sys_rst(sys_rst),
	.sys_clk(sys_clk),
	.xgemac_clk_156(sys_clk),
	// Phy
	.xgmii_0_txd(xgmii_0_txd),
	.xgmii_0_txc(xgmii_0_txc),
	.xgmii_0_rxd(xgmii_0_rxd),
	.xgmii_0_rxc(xgmii_0_rxc),
	.xphy_0_status(xphy_0_status),
	.xgmii_1_txd(xgmii_1_txd),
	.xgmii_1_txc(xgmii_1_txc),
	.xgmii_1_rxd(xgmii_1_rxd),
	.xgmii_1_rxc(xgmii_1_rxc),
	.xphy_1_status(xphy_1_status),
	// LED and Switches
	.button_n(button_n),
	.button_s(button_s),
	.button_w(button_w),
	.button_e(button_e),
	.button_c(button_c),
	// ---- DIP SW
	.dipsw(dipsw),
	// ---- LED
	.led(led)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

/*
always @(posedge Wclk) begin
	if (WriteEn_in == 1'b1)
		$display("Data_in: %x", Data_in);
end
*/

`ifdef NO
reg [23:0] tlp_rom [0:4095];
reg [11:0] phy_rom [0:4095];
reg [11:0] tlp_counter, phy_counter;
wire [23:0] tlp_cur;
wire [11:0] phy_cur;
assign tlp_cur = tlp_rom[ tlp_counter ];
assign phy_cur = phy_rom[ phy_counter ];

always @(posedge sys_clk) begin
	rx_st   <= tlp_cur[20];
	rx_end  <= tlp_cur[16];
	rx_data <= tlp_cur[15:0];
	tlp_counter <= tlp_counter + 1;
end

always @(posedge sys_clk) begin
	gmii_rx_dv  <= phy_cur[8];
	gmii_rxd    <= phy_cur[7:0];
	phy_counter <= phy_counter + 1;
end
`endif

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_system); 
//	$readmemh("./tlp_data.hex", tlp_rom);
//	$readmemh("./phy_data.hex", phy_rom);
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
//	tlp_counter = 0;
//	phy_counter = 0;

	waitclock;
	waitclock;

	sys_rst = 1'b0;

	waitclock;

//	#(1*16) ethpipe_mid_inst.global_counter[47:0] = 64'h2000;
//	#(60*16) ethpipe_mid_inst.tx0mem_wr_ptr = 12'h4c;
//	#(180*16) ethpipe_mid_inst.tx0mem_wr_ptr = 12'h72;
//	#(240*16) ethpipe_mid_inst.tx0mem_wr_ptr = 12'hd8;

//	#(8*2) mst_req_o = 1'b0;

	#10000;

	$finish;
end
`endif

endmodule

