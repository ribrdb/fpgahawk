// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
// Specify the module to load or on files.f
`include "DataSeparator.sv"
`timescale 10 ns / 100 ps

module DataSeparator_testbench();

   `SVUT_SETUP

     parameter CLOCK_WINDOW_START = 17;
   parameter   CLOCK_WINDOW_END = 23;
   parameter   DATA_WINDOW_START = 5;
   parameter   DATA_WINDOW_END = 15;
   parameter   MAX_TEST_BITS = 16;

   logic       wr_clock;
   logic       wr_data;
   logic       hf_clk;
   logic       en;
   logic       dsk_wr_data_clk;

   logic [3:0] initial_delay;
   reg [15:0]  cnt_data_clocks;
   reg [MAX_TEST_BITS-1:0] data_bits;

   DataSeparator 
     #(
       .CLOCK_WINDOW_START (7),
       .CLOCK_WINDOW_END   (9),
       .DATA_WINDOW_START  (2),
       .DATA_WINDOW_END    (6)
       )
   dut 
     (
      .wr_clock        (wr_clock),
      .wr_data         (wr_data),
      .hf_clk          (hf_clk),
      .en              (en),
      .dsk_wr_data_clk (dsk_wr_data_clk)
      );


   // To create a clock:
   initial hf_clk = 0;
   always #2 hf_clk = ~hf_clk;
   always @(posedge wr_clock) begin
      cnt_data_clocks = cnt_data_clocks + 1;
      data_bits = {data_bits[MAX_TEST_BITS-2:0],wr_data};
   end

   // To dump data for visualization:
   initial begin
      $dumpfile("sim/DataSeparator_testbench.fst");
      $dumpvars(0, DataSeparator_testbench);
   end

   // Setup time format when printing with $realtime()
   initial $timeformat(-9, 1, "ns", 8);

   task setup(msg="");
      begin
         // setup() runs when a test begins
         en = 0;
         dsk_wr_data_clk = 0;
         cnt_data_clocks = 0;
         data_bits = 0;
         #10;
      end
   endtask

   task teardown(msg="");
      begin
         // teardown() runs when a test ends
         #50;

      end
   endtask

   `TEST_SUITE("TESTSUITE_NAME")

   //  Available macros:"
   //
   //    - `MSG("message"):       Print a raw white message
   //    - `INFO("message"):      Print a blue message with INFO: prefix
   //    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
   //    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
   //    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
   //    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
   //
   //    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
   //    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
   //    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
   //    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
   //    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
   //    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
   //
   //  Available flag:
   //
   //    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

   `UNIT_TEST("clock only, a bit fast")

   // Describe here the testcase scenario
   //
   // Because SVUT uses long nested macros, it's possible
   // some local variable declaration leads to compilation issue.
   // You should declare your variables after the IOs declaration to avoid that.
   initial_delay = $random;

   #50;
   #(initial_delay);
   en <= 1;
   #1 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;
   #27 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;
   #27 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;

   repeat (4) @(posedge hf_clk);

   `FAIL_IF_NOT_EQUAL(cnt_data_clocks, 2);
   `FAIL_IF_NOT_EQUAL(data_bits, 0);
   



   `UNIT_TEST_END

   `UNIT_TEST("no clock output if not enabled")

   en <= 0;
   initial_delay = $random;

   #50;
   #(initial_delay);
   #1 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;
   #27 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;
   #27 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;

   repeat (4) @(posedge hf_clk);

   $display("clocks: %d", cnt_data_clocks);
   $display("data: %b", data_bits);

   `FAIL_IF_NOT_EQUAL(cnt_data_clocks, 0);
   `FAIL_IF_NOT_EQUAL(data_bits, 0);
   
   `UNIT_TEST_END


   `UNIT_TEST("clock + data")

   en <= 1;
   initial_delay = $random;

   #50;
   //#(initial_delay);
   
   repeat (5) begin
      #31 dsk_wr_data_clk <= 1;
      #1 dsk_wr_data_clk <= 0;
   end
   repeat (4) begin
      #15 dsk_wr_data_clk <= 1;
      #1 dsk_wr_data_clk <= 0;
   end
   #30 dsk_wr_data_clk <= 1;
   #1 dsk_wr_data_clk <= 0;
   repeat (4) begin
      #15 dsk_wr_data_clk <= 1;
      #1 dsk_wr_data_clk <= 0;
   end
   repeat (4) @(posedge hf_clk);

   `FAIL_IF_NOT_EQUAL(cnt_data_clocks, 9);
   `FAIL_IF_NOT_EQUAL(data_bits, 9'b0000011011);
   `UNIT_TEST_END


`TEST_SUITE_END

endmodule
