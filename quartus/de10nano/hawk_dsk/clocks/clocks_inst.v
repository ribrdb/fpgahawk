	clocks u0 (
		.clk_clk             (<connected-to-clk_clk>),             //           clk.clk
		.pll_0_clk_100_clk   (<connected-to-pll_0_clk_100_clk>),   // pll_0_clk_100.clk
		.pll_0_clk_25_clk    (<connected-to-pll_0_clk_25_clk>),    //  pll_0_clk_25.clk
		.pll_0_clk_2_5_clk   (<connected-to-pll_0_clk_2_5_clk>),   // pll_0_clk_2_5.clk
		.pll_0_locked_export (<connected-to-pll_0_locked_export>), //  pll_0_locked.export
		.pll_1_locked_export (<connected-to-pll_1_locked_export>), //  pll_1_locked.export
		.pll_1_outclk0_clk   (<connected-to-pll_1_outclk0_clk>),   // pll_1_outclk0.clk
		.reset_reset_n       (<connected-to-reset_reset_n>)        //         reset.reset_n
	);

