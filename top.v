`timescale 1ns / 1ps

module top_module(clk, rst, ps2_data_in, ps2_clk_in,switch, led_out,sseg, anode);

input clk, rst;
input [3:0] switch;
input wire ps2_data_in;
input wire ps2_clk_in;
output [7:0] led_out;
output [7:0] sseg;
output [3:0] anode;

reg [9:0] addr_toRAM_o;
reg [31:0] data_toRAM_o;
wire [31:0] data_fromRAM_o;
reg wrEn_o;

wire [9:0] addr_toRAM_CPU;
wire [31:0] data_toRAM_CPU;
wire wrEn_CPU;

wire [15:0] bcd_out;
wire [12:0] bcd_in;

wire [7:0] digit1;
wire [7:0] digit2;
wire [7:0] digit3;
wire [7:0] digit4;

reg  [4:0] q;
reg rst_flag;

always@(posedge clk) begin
	q[0] <= rst;
	q[1] <= q[0];
	q[2] <= q[1];
	q[3] <= q[2];
	q[4] <= q[3];
	rst_flag <= (q[4] && (!q[3]) && (!q[2]) && (!q[1]));
end

SimpleCPU SimpleCPU( .clk(clk), .rst(rst_flag), .wrEn(wrEn_CPU), .data_fromRAM(data_fromRAM_o), .addr_toRAM(addr_toRAM_CPU), .data_toRAM(data_toRAM_CPU) );

binary2bcd B_2_BCD (clk, rst_flag, bcd_in, bcd_out);

RAM MY_Double_RAM (
	.clka(clk), 
	.wea(wrEn_o), // input [0 : 0] wea 
	.addra(addr_toRAM_o), // input [9 : 0] addra
	.dina(data_toRAM_o), // input [31 : 0] dina
	.douta(data_fromRAM_o), // output [31 : 0] douta

	.clkb(clk), // input clkb
	.web(1'b0), // input [0 : 0] web
	.addrb(10'd101), // input [9 : 0] addrb
	.dinb(32'b0), // input [31 : 0] dinb
	.doutb(bcd_in) // output [31 : 0] doutb
);

wire [7:0] keybord_code;
wire keybord_ready;
reg [2:0] data_out;

ps2_port ps2(rst_flag, clk, ps2_data_in, ps2_clk_in, keybord_code, keybord_ready);


   always @(posedge clk) begin
	if (keybord_ready==1'b1)begin
      case (keybord_code)
         8'h16:   
            data_out <= 8'd1; // 1
         8'h1E:   
            data_out <= 8'd2; // 2
         8'h26:   
            data_out <= 8'd3; // 3
         8'h25:   
            data_out <= 8'd4; // 4
         8'h2E:
            data_out <= 8'd5; // 5
         8'h36:
            data_out <= 8'd6; // 6
         8'h3D:
            data_out <= 8'd7; // 7
         8'h69:// Numpad Start
            data_out <= 8'd1; // 1
         8'h72:   // 2
            data_out <= 8'd2; // 2
         8'h7A:   
            data_out <= 8'd3; // 3
         8'h6B:   
            data_out <= 8'd4; // 4
         8'h73:   
            data_out <= 8'd5; // 5
         8'h74:   
            data_out <= 8'd6; // 6
         8'h6C:   
            data_out <= 8'd7; // 7
         default:
            data_out <= 8'h1; // Return Of Sit
      endcase
		end
   end

//Port A
always @(posedge clk)
begin
	if( rst_flag == 1'b1) begin
		addr_toRAM_o <= 10'd1022; // Put data to Address 1022.
		if (switch[3]==1'b1) begin
			data_toRAM_o <= data_out; 	// Put first 3 bit.
		end
		else begin
			if (switch[2:0] == 1'b0) begin // 0 condition
				data_toRAM_o <= 1'b1;
			end
			else begin
				data_toRAM_o <= switch[2:0]; // Put first 3 bit.	
			end
		end
		wrEn_o <= 1'b1; 				// Just Write.
	end
	else begin
		addr_toRAM_o <= addr_toRAM_CPU; // Put CPU Address.
		data_toRAM_o <= data_toRAM_CPU; // Put CPU Data.
		wrEn_o <= wrEn_CPU;
	end
end

kitt wow (led_out, clk);

ssd_decoder digit1_decoder (bcd_out[3:0], digit1);
ssd_decoder digit2_decoder (bcd_out[7:4], digit2);
ssd_decoder digit3_decoder (bcd_out[11:8], digit3);
ssd_decoder digit4_decoder (bcd_out[15:12], digit4);

scan_unit scan_unit_All (.clk_s(clk), .rst_s(rst_flag), .sseg_s({digit4,digit3,digit2,digit1}), .anode_s(anode), .sout_s(sseg));

endmodule
