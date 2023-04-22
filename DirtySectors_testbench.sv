// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
// Specify the module to load or on files.f
`include "DirtySectors.sv"
`timescale 1 ns / 100 ps

module DirtySectors_testbench();

    `SVUT_SETUP

    reg[63:0] dirty_sectors;
    logic all_clean;
    logic clk;
    logic reset_n;
    logic en;
    logic[5:0] saddr;
    logic d;

    DirtySectors 
    dut 
    (
    .dirty_sectors (dirty_sectors),
    .all_clean     (all_clean),
    .clk           (clk),
    .reset_n       (reset_n),
    .en            (en),
    .saddr         (saddr),
    .d             (d)
    );


    initial clk = 0;
    always #2 clk = ~clk;

    initial begin
        $dumpfile("sim/DirtySectors_testbench.fst");
        $dumpvars(0, DirtySectors_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        reset_n = 1;
    end
    endtask

    task teardown(msg="");
    begin
        reset_n = 0;
        #1 reset_n = 1;
    end
    endtask

    `TEST_SUITE("DirtySectors")

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

    `UNIT_TEST("Set and Clear")

        `FAIL_IF(dirty_sectors);
        `FAIL_IF_NOT(all_clean);
        @(posedge clk);
        en = 1;
        d = 1;
        saddr = 3;

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'd8);
        saddr = 0;

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'd9);

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'd9);
        saddr = 63;

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'h7000000000000009);
        d = 0;
        saddr = 0;

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'h7000000000000008);
        saddr = 0;

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'h7000000000000008);
        saddr = 3;

        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 64'h7000000000000000);
        saddr = 63;

        @(posedge clk);
        `FAIL_IF_NOT(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 0);
        saddr = 63;

    `UNIT_TEST_END

    `UNIT_TEST("Reset")

        `FAIL_IF(dirty_sectors);
        `FAIL_IF_NOT(all_clean);
        @(posedge clk);
        en = 1;
        d = 1;
        saddr = 3;
        @(posedge clk);
        saddr = 4;
        @(posedge clk);
        saddr = 5;
        @(posedge clk);
        `FAIL_IF(all_clean);
        `FAIL_IF_EQUAL(dirty_sectors, 0);

        reset_n = 0;
        #1 reset_n = 1;
        `FAIL_IF_NOT(all_clean);
        `FAIL_IF_NOT_EQUAL(dirty_sectors, 0);

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
