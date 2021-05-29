`timescale 1ns / 1ps

/** Module to read data from a PS/2 port.
 * @param rst_in Asynchronous reset.
 * @param clk_in Clock.
 * @param ps2_data_in PS/2 data line.
 * @param ps2_clk_in PS/2 clock line.
 * @param data_out Data output.
 * @param ready_out Set when data is ready, cleared when data is being read.
 */
module ps2_port(rst_in, clk_in, ps2_data_in, ps2_clk_in, data_out, ready_out);

   input wire rst_in;
   input wire clk_in;
   input wire ps2_data_in;
   input wire ps2_clk_in;
   output reg [7:0] data_out;
   output reg ready_out;

   // Buffer the PS/2 clock and data signals.
   reg ps2_data;
   reg ps2_clk;
   always @(posedge clk_in) begin
      ps2_data <= ps2_data_in;
      ps2_clk <= ps2_clk_in;
   end

   // Read data coming from the port.
   // Format is 1 start bit, 8 bits of data, 1 parity bit, 1 stop bit.
   reg [3:0] state;
   wire [3:0] next_state = state + 1;
   reg got_clk;
   always @(posedge clk_in or posedge rst_in) begin
      if (rst_in) begin
         state <= 0;
         data_out <= 0;
         got_clk <= 0;
         ready_out <= 0;
      end else if (~ps2_clk & ~got_clk) begin
         case (state)
            1, 2, 3, 4, 5, 6, 7, 8:
               begin
                  data_out <= {ps2_data, data_out[7:1]};
                  state <= next_state;
                  ready_out <= 0;
               end
            9:
               begin
                  state <= 10;
                  ready_out <= 1;
               end
            10:
               begin
                  state <= 0;
                  ready_out <= 0;
               end
            default:
               begin
                  state <= ps2_data ? 0 : 1;
                  ready_out <= 0;
               end
         endcase
         got_clk <= 1;
      end else begin
         ready_out <= 0;
         if (ps2_clk) got_clk <= 0;
      end
   end

endmodule


