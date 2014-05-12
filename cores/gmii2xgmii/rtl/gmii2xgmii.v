module gmii2xgmii (
	input         sys_rst,
	input         sys_156,
	// GMII interface
	input         gmii_rx_clk,
	input         gmii_rx_dv,
	input   [7:0] gmii_rxd,
	input         gmii_gtx_clk,
	output        gmii_tx_en,
	output  [7:0] gmii_txd,

	// XGMII interface
	input  [63:0] xgmii_txd,
	input   [7:0] xgmii_txc,
	output reg [63:0] xgmii_rxd,
	output reg  [7:0] xgmii_rxc,
);

parameter IDLE  = 8'h07;
parameter START = 8'hfb;
parameter STOP  = 8'hfd;

reg rx_counter [11:0];
reg [1:0] state;

parameter SYS_IDLE  = 2'h0;
parameter SYS_DATA  = 2'h1;
parameter SYS_START = 2'h2; 
parameter SYS_STOP  = 2'h3;

always @(posedge gmii_rx_clk) begin
	if (sys_rst) begin
		state <= SYS_IDLE;
		rx_counter <= 12'h0;
	end else begin
		if (gmii_rx_dv == 1'b1 || rx_counter[2:0] != 3'h0) begin
			rx_counter <= rx_counter + 12'h1;
			xgmii_rxd <= {gmii_rxd[7:0], xgmii[63:8]};
			xgmii_rxc <= {gmii_rx_dv, xgmii_rxc[7:1]};
		end else begin
			rx_counter <= 12'h0;
		end
	end
end

endmodule
