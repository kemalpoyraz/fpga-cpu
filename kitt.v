module kitt(led_out, clk);
	output [7:0] led_out;
	input clk;
	reg [7:0] led_out=8'h01;
	reg div_clk=1'b0;
	reg [25:0] counter=26'b0;
	reg direction=1'b0;

	always @(posedge div_clk) begin
		if(direction==1'b0)
		begin
			led_out = led_out << 8'h01;					
			led_out = led_out + 8'h01;					
		end
		else
		   led_out = led_out >> 8'h01;
		   
		if(led_out==8'hFF)
			direction=1'b1;
		if(led_out==8'h01)
		begin 
			direction=1'b0;
		end
	end
	always @(posedge clk)
	begin
		if(counter==26'd5000000)
		begin
			counter=26'b0;
			div_clk = ~div_clk;
		end
		else
			counter = counter + 1'b1;
	end
endmodule