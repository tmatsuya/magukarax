module dpram # (
	parameter ADDR_WIDTH = 12,
	parameter DATA_WIDTH = 32
) (
	input clka,
	input clkb,
	input wea,
	input web,
	input [ADDR_WIDTH-1:0] addra,
	input [ADDR_WIDTH-1:0] addrb,
	input [DATA_WIDTH-1:0] dina,
	input [DATA_WIDTH-1:0] dinb,
	output reg [DATA_WIDTH-1:0] douta,
	output reg [DATA_WIDTH-1:0] doutb
);

parameter RAM_DEPTH = 1 << ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];

always @(posedge clka) begin
	if (wea)
		mem[addra] <= dina;
	douta <= mem[addra];
end

always @(posedge clkb) begin
	if (web)
		mem[addrb] <= dinb;
	doutb <= mem[addrb];
end

endmodule
