// DataSeparator reads the combined write data/clock from the Hawk drive
// and outputs the data.
//
// It uses a high frequency counter to measure the time between pulses
// on the data/clock line. 
// The incoming data should always start with several 0s.
// Once two pulses are identified that are between CLOCK_WINDOW_START and CLOCK_WINDOW_END ticks apart, the signal is locked.
// Then if a pulse is detected between DATA_WINDOW_START and DATA_WINDOW_END ticks after a clock tick, it is treated as a 1 data bit.

module DataSeparator 
  #(
     parameter CLOCK_WINDOW_START = 17, // min hf_clk ticks between clock pulses
     parameter CLOCK_WINDOW_END = 23, // max hf_clk ticks between a clock pulses
     parameter DATA_WINDOW_START = 5, // min hf_clk ticks between a clock pulse and a data pulse
     parameter DATA_WINDOW_END = 15 // max hf_clk ticks between a clock pulse and a data pulse
    )
   (
    // Outputs
     output reg wr_clock,
     output reg wr_data,

    // Inputs
     input wire hf_clk,
     input wire en,
     input wire dsk_wr_data_clk
    );

   localparam MAX = CLOCK_WINDOW_END+1;
   localparam COUNTER_WIDTH = $clog2(MAX);

   localparam CLOCK_PULSE = 4'b11?0,
              DATA_PULSE = 4'b1010, MISSING_PULSE = 4'b0001, RESTART = 4'b1??1;
   
   reg [COUNTER_WIDTH:0] counter = 0;
   reg                   async_toggle = 0;
   
   reg                   async_data_1 = 0;
   reg                   async_data_2 = 0;
   reg                   async_data_3 =0;
   reg                   next_data=0;

   logic                  sync_data;
   wire                  in_clock_window;
   wire                  in_data_window;
   wire                  missing_clock;
   

   // Body

   assign sync_data = async_data_2 ^ async_data_3;
   assign in_clock_window = (counter >= CLOCK_WINDOW_START && counter <= CLOCK_WINDOW_END);
   assign in_data_window = (counter >= DATA_WINDOW_START && counter <= DATA_WINDOW_END);
   assign missing_clock = (counter >= MAX);
   

   always @ (posedge dsk_wr_data_clk) async_toggle = en ? ~async_toggle : async_toggle;
   
   always @ (posedge hf_clk) begin
      async_data_1 <= async_toggle;
      async_data_2 <= async_data_1;
      async_data_3 <= async_data_2;
   end
   
   always @ (posedge hf_clk) begin
      casez ({sync_data,
              in_clock_window,
              in_data_window,
              missing_clock})
        CLOCK_PULSE: begin
           counter <= 1;
           wr_clock <= 1;
           wr_data <= next_data;
           next_data <= 0;
        end
        DATA_PULSE: begin
           counter <= counter + 1;
           wr_clock <= 0;
           wr_data <= 0;
           next_data <= 1;
        end
        MISSING_PULSE: begin
           counter <= counter;
           wr_clock <= 0;
           wr_data <= 0;
           next_data <= 0;
        end
        RESTART: begin
           counter <= 1;
           wr_clock <= 0;
           wr_data <= 0;
           next_data <= 0;
        end

        default: begin
           counter <= counter + 1;
           next_data <= next_data;
           wr_clock <= 0;
           wr_data <= 0;
        end
        
      endcase
   end

endmodule
