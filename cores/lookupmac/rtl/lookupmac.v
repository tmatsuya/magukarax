module lookupmac # (
	parameter MaxPort = 4'h3
) (
	// interface
	input         sys_rst,
	input         sys_clk,

        input         req0,
        input [47:0]  src_mac0,
        input [47:0]  dest_mac0,
        output reg    ack0,
        output reg [4:0] forward_port0,

);

//-----------------------------------
// logic
//-----------------------------------
`ifdef NO
function [1:0] fib2;
input [3:0] addr;
case (addr)
	4'h0: fib2 = rd_data[ 1: 0];
	4'h1: fib2 = rd_data[ 3: 2];
	4'h2: fib2 = rd_data[ 5: 4];
	4'h3: fib2 = rd_data[ 7: 6];
	4'h4: fib2 = rd_data[10: 9];
	4'h5: fib2 = rd_data[12:11];
	4'h6: fib2 = rd_data[14:13];
	4'h7: fib2 = rd_data[16:15];
	4'h8: fib2 = rd_data[19:18];
	4'h9: fib2 = rd_data[21:20];
	4'ha: fib2 = rd_data[23:22];
	4'hb: fib2 = rd_data[25:24];
	4'hc: fib2 = rd_data[28:27];
	4'hd: fib2 = rd_data[30:29];
	4'he: fib2 = rd_data[32:31];
	4'hf: fib2 = rd_data[34:33];
endcase
endfunction

parameter IDLE = 3'h0;

reg [2:0] state = IDLE;

always @(posedge sys_clk) begin
	if (sys_rst) begin
		ack0 <= 1'b0;
		forward_port0 <= 5'b00000;
	end else begin
		ack0 <= 1'b1;
		case (state)
			IDLE: begin
				forward_port0 <= 5'b11111;
			end
		endcase
	end
end

endmodule
