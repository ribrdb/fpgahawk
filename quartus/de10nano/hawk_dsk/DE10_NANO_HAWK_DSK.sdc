#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK2_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK3_50]

# for enhancing USB BlasterII to be reliable, 25MHz
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks
create_generated_clock -name dsk_wr_data -source [get_pins {qsys0|pll_1|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -divide_by 2 [get_registers {FakeDSK:dsk0|hawk_wr_data}]
create_generated_clock -name dsk_cyl_strobe -source [get_pins {qsys0|pll_1|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -divide_by 1 [get_registers {FakeDSK:dsk0|hawk_cyl_strobe}]

#derive_clocks -period 10


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous -group [get_clocks {qsys0|pll_0|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_clock_groups -asynchronous -group [get_clocks {qsys0|pll_0|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_clock_groups -asynchronous -group [get_clocks {qsys0|pll_0|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_clock_groups -asynchronous -group [get_clocks {qsys0|pll_1|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_clock_groups -asynchronous -group [get_clocks {dsk_wr_data}]
set_clock_groups -asynchronous -group [get_clocks {dsk_cyl_strobe}]


#**************************************************************
# Set False Path
#**************************************************************
set_false_path -to probes*
set_false_path -from probes*
set_false_path -from qsys0|pll_1|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]
set_false_path -from qsys0|pll_0|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]
set_false_path -from {qsys0|pll_0|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk} -to {sld_signaltap:auto_signaltap_0|acq_data_in_reg[3]}
set_false_path -from {qsys0|pll_0|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk} -to {sld_signaltap:auto_signaltap_0|acq_trigger_in_reg[3]}

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



