`timescale 1ps / 1ps
`define SIMULATION
//`include "../rtl/setup.v"
module tb_system();

/* 125MHz system clock */
reg         sys_rst;
reg         sys_clk;	// clk156
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

// XGMII interfaces for 4 MACs
wire [63:0] xgmii_0_txd;
wire [7:0]  xgmii_0_txc;
reg  [63:0] xgmii_0_rxd;
reg  [7:0]  xgmii_0_rxc;

wire [63:0] xgmii_1_txd;
wire [7:0]  xgmii_1_txc;
reg  [63:0] xgmii_1_rxd;
reg  [7:0]  xgmii_1_rxc;

wire [63:0] xgmii_2_txd;
wire [7:0]  xgmii_2_txc;
reg  [63:0] xgmii_2_rxd;
reg  [7:0]  xgmii_2_rxc;

wire [63:0] xgmii_3_txd;
wire [7:0]  xgmii_3_txc;
wire [63:0] xgmii_3_rxd;
wire [7:0]  xgmii_3_rxc;

// LED and Switches
reg [7:0] dipsw;
wire [7:0] led;
wire [13:0] segled;
reg btn;

measure measure_inst (
         .sys_rst   (sys_rst),
         .sys_clk   (sys_clk),

  // XGMII interfaces for 4 MACs
	.xgmii_0_txd(xgmii_0_txd),
	.xgmii_0_txc(xgmii_0_txc),
	.xgmii_0_rxd(xgmii_0_rxd),
	.xgmii_0_rxc(xgmii_0_rxc),

	.xgmii_1_txd(xgmii_1_txd),
	.xgmii_1_txc(xgmii_1_txc),
	.xgmii_1_rxd(xgmii_1_rxd),
	.xgmii_1_rxc(xgmii_1_rxc),

	.xgmii_2_txd(xgmii_2_txd),
	.xgmii_2_txc(xgmii_2_txc),
	.xgmii_2_rxd(xgmii_2_rxd),
	.xgmii_2_rxc(xgmii_2_rxc),

	.xgmii_3_txd(xgmii_3_txd),
	.xgmii_3_txc(xgmii_3_txc),
	.xgmii_3_rxd(xgmii_3_rxd),
	.xgmii_3_rxc(xgmii_3_rxc)
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

reg [23:0] tlp_rom [0:4095];
reg [11:0] phy_rom [0:4095];
reg [11:0] tlp_counter, phy_counter;
wire [23:0] tlp_cur;
wire [23:0] phy_cur;
assign tlp_cur = tlp_rom[ tlp_counter ];
assign phy_cur = phy_rom[ phy_counter ];

always @(posedge sys_clk) begin
//	rx_st   <= tlp_cur[20];
//	rx_end  <= tlp_cur[16];
//	rx_data <= tlp_cur[15:0];
//	tlp_counter <= tlp_counter + 1;
end

always @(posedge sys_clk) begin
//	gmii_rx_dv  <= phy_cur[8];
//	gmii_rxd <= phy_cur[7:0];
//	phy_counter <= phy_counter + 1;
end

initial begin
        $dumpfile("./test.vcd");
	$dumpvars(0, tb_system); 
	$readmemh("./tlp_data.hex", tlp_rom);
	$readmemh("./phy_data.hex", phy_rom);
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;

	waitclock;
	waitclock;

	sys_rst = 1'b0;

	waitclock;

//	#(500*16) mst_req_o = 1'b1;

//	#(8*2) mst_req_o = 1'b0;

	#4000;

	$finish;
end

endmodule
