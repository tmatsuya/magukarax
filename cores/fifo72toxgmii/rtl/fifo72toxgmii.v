
module fifo72toxgmii (
	// FIFO
	input         sys_rst,
	input [71:0]  dout,
	input         empty,
	output        rd_en,
	output        rd_clk,
	// XGMII
	input         xgmii_tx_clk,
	output [71:0] xgmii_txd
);

assign rd_clk = xgmii_tx_clk;

//-----------------------------------
// logic
//-----------------------------------

reg [71:0] txd;

always @(posedge xgmii_tx_clk) begin
	if (sys_rst) begin
		txd <= 72'hff_07_07_07_07_07_07_07_07;
	end else begin
		if (empty  == 1'b0) begin
			txd <= dout[71: 0];
		end else begin
			txd <= 72'hff_07_07_07_07_07_07_07_07;
		end
	end
end

assign rd_en = ~empty;
assign xgmii_txd   = txd;

endmodule
