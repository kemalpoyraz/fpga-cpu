//A seven-segment display (SSD) decoder
//This circuit decodes binary-coded decimal (BCD) numbers into corresponding seven-segment display representation

module ssd_decoder(bcd, ssd);

	input [3:0] bcd;
	output reg [7:0] ssd;
	
	always@(*) begin

		case(bcd)
			4'b0000: ssd[7:0] = 8'h03;
			4'b0001: ssd[7:0] = 8'h9F;
			4'b0010: ssd[7:0] = 8'h25;
			4'b0011: ssd[7:0] = 8'h0D;
			4'b0100: ssd[7:0] = 8'h99;
			4'b0101: ssd[7:0] = 8'h49;
			4'b0110: ssd[7:0] = 8'h41;
			4'b0111: ssd[7:0] = 8'h1F;
			4'b1000: ssd[7:0] = 8'h01;
			4'b1001: ssd[7:0] = 8'h09;
			default: ssd[7:0] = 8'hFF;
		endcase
		
	end

endmodule

//A scanning display controller
//This circuit drives the anode signals and corresponding segments of each digit in a repeating,
//continuous succession, at an update rate that is faster than the human eye response

module scan_unit(clk_s, rst_s, sseg_s, anode_s, sout_s);

	input clk_s, rst_s;
	input [31:0] sseg_s;
	output [7:0] sout_s;
	output  [3:0] anode_s;
	
	reg [7:0] sout_s;
	reg [3:0] anode_s;
	reg [14:0] cntr;
	
	always @(posedge clk_s) begin
			if(rst_s) begin
				cntr<=15'd0;
				sout_s <= 8'b11111111;
			end else begin
				cntr <= cntr +1;
			   if (cntr>15'd24000 && cntr<15'd31000)begin
					sout_s<=sseg_s[31:24];
					anode_s<=4'b0111;
				end
				else if (cntr>15'd16000 && cntr<15'd23000)begin
					sout_s<=sseg_s[23:16];
					anode_s<=4'b1011;
				end
				else if (cntr>15'd8000 && cntr<15'd15000)begin
					sout_s<=sseg_s[15:8];
					anode_s<=4'b1101;
				end
				else if (cntr>15'b0 && cntr<15'd7000)begin
					sout_s<=sseg_s[7:0];
					anode_s<=4'b1110;
				end
			end		
   end

endmodule
