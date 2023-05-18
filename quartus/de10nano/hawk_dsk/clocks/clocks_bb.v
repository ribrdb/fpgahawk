
module clocks (
	clk_clk,
	pll_0_clk_100_clk,
	pll_0_clk_25_clk,
	pll_0_clk_2_5_clk,
	pll_0_locked_export,
	pll_1_locked_export,
	pll_1_outclk0_clk,
	reset_reset_n);	

	input		clk_clk;
	output		pll_0_clk_100_clk;
	output		pll_0_clk_25_clk;
	output		pll_0_clk_2_5_clk;
	output		pll_0_locked_export;
	output		pll_1_locked_export;
	output		pll_1_outclk0_clk;
	input		reset_reset_n;
endmodule
