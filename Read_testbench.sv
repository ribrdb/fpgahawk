// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
// Specify the module to load or on files.f
`include "Read.sv"
`timescale 100 ns / 100 ps

module Read_testbench();

    `SVUT_SETUP

    logic clk;
    logic[1:0] hs;
    logic[8:0] cyl;
    logic[4:0] sect;
    logic[7:0] data_in;
    logic sector_strobe;
    logic rd_en;
    logic data_area;
    reg[8:0] addr_out;
    logic data_out;
    logic prefetch;

    reg [7:0] mem[511:0];

    logic [7:0] data;
    logic [15:0] addr;

    Read 
    dut 
    (
    .clk            (clk),
    .hs             (hs),
    .cyl            (cyl),
    .sect           (sect),
    .data_in        (data_in),
    .sector_strobe  (sector_strobe),
    .rd_en          (rd_en),
    .data_area      (data_area),
    .addr_out       (addr_out),
    .data_out       (data_out),
    .prefetch       (prefetch)
    );


    // To create a clock:
    initial clk = 0;
    always #2 clk = ~clk;

    always @(posedge clk) data_in = mem[addr_out];
    always @(posedge clk) data = {data[6:0], data_out};
    always @(posedge clk) addr = {data_out, addr[15:1]};

    // To dump data for visualization:
    initial begin
        $dumpfile("sim/Read_testbench.fst");
        $dumpvars(0, Read_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    integer i;
    task setup(msg="");
    begin
        // setup() runs when a test begins
        for (i = 0; i < 400; i = i + 1)
            mem[i] = i[7:0]^i[15:8];
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
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

    `UNIT_TEST("TESTCASE_NAME")

        // Describe here the testcase scenario
        //
        // Because SVUT uses long nested macros, it's possible
        // some local variable declaration leads to compilation issue.
        // You should declare your variables after the IOs declaration to avoid that.
        hs = 2'b11;
        cyl = 9'b011010100;
        sect = 5'b00110;
        // wait for sync bit
        @(posedge data_out);
        @(posedge clk);
        repeat (16) @(posedge clk);
        #1 $display("%b", addr);
        `FAIL_IF_NOT_EQUAL(addr, 16'b1101101010000110, "invalid address");
        repeat (20) @(posedge clk);
        // wait for next sync bit
        @(posedge data_out);
        @(posedge clk);
        for (i = 0; i < 400; i = i + 1) begin
            repeat (8) @(posedge clk);
            #1 $display("%h %h", i[11:0], data);
            `FAIL_IF_NOT_EQUAL(data, i[7:0]^i[15:8]);
        end

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
