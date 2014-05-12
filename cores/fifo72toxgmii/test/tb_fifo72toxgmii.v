module tb_fifo72toxgmii();

/* 125MHz system clock */
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

/* 33MHz PCI clock */
reg pci_clk;
initial pci_clk = 1'b0;
always #30 pci_clk = ~pci_clk;

/* 62.5MHz CPCI clock */
reg cpci_clk;
initial cpci_clk = 1'b0;
always #16 cpci_clk = ~cpci_clk;

/* 125MHz RX clock */
reg phy_rx_clk;
initial phy_rx_clk = 1'b0;
always #8 phy_rx_clk = ~phy_rx_clk;

/* 125MHz TX clock */
reg phy_tx_clk;
initial phy_tx_clk = 1'b0;
always #8 phy_tx_clk = ~phy_tx_clk;


reg sys_rst;
reg [71:0] dout;
reg empty;
wire rd_en;
wire rd_clk;
wire [71:0] xgmii_txd;

fifo72toxgmii fifo72toxgmii_tb (
	.sys_rst(sys_rst),

	.dout(dout),
	.empty(empty),
	.rd_en(rd_en),
	.rd_clk(rd_clk),

	.xgmii_tx_clk(phy_tx_clk),
	.xgmii_txd(xgmii_txd)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

always @(posedge rd_clk) begin
	if (xgmii_txd[71:64] != 8'hff)
		$display("xgmii_tx_out: %x", xgmii_txd);
end

reg [11:0] counter;
reg [71:0] rom [0:4091];

always #1
	{empty,dout} <= rom[ counter ];

always @(posedge phy_tx_clk) begin
	if (rd_en == 1'b1)
		counter <= counter + 1;
end

initial begin
        $dumpfile("./test.vcd");
	$dumpvars(0, tb_fifo72toxgmii);
	$readmemh("./fifo72.hex", rom);
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	counter = 0;

	waitclock;
	waitclock;

	sys_rst = 1'b0;

	waitclock;


	#30000;

	$finish;
end

endmodule
