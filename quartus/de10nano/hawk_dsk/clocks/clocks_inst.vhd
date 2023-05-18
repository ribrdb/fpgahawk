	component clocks is
		port (
			clk_clk             : in  std_logic := 'X'; -- clk
			pll_0_clk_100_clk   : out std_logic;        -- clk
			pll_0_clk_25_clk    : out std_logic;        -- clk
			pll_0_clk_2_5_clk   : out std_logic;        -- clk
			pll_0_locked_export : out std_logic;        -- export
			pll_1_locked_export : out std_logic;        -- export
			pll_1_outclk0_clk   : out std_logic;        -- clk
			reset_reset_n       : in  std_logic := 'X'  -- reset_n
		);
	end component clocks;

	u0 : component clocks
		port map (
			clk_clk             => CONNECTED_TO_clk_clk,             --           clk.clk
			pll_0_clk_100_clk   => CONNECTED_TO_pll_0_clk_100_clk,   -- pll_0_clk_100.clk
			pll_0_clk_25_clk    => CONNECTED_TO_pll_0_clk_25_clk,    --  pll_0_clk_25.clk
			pll_0_clk_2_5_clk   => CONNECTED_TO_pll_0_clk_2_5_clk,   -- pll_0_clk_2_5.clk
			pll_0_locked_export => CONNECTED_TO_pll_0_locked_export, --  pll_0_locked.export
			pll_1_locked_export => CONNECTED_TO_pll_1_locked_export, --  pll_1_locked.export
			pll_1_outclk0_clk   => CONNECTED_TO_pll_1_outclk0_clk,   -- pll_1_outclk0.clk
			reset_reset_n       => CONNECTED_TO_reset_reset_n        --         reset.reset_n
		);

