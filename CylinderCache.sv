// CylinderCache is a dual port, dual clock ram for storing the contents of
// a single hawk drive cylinder.
// Port A is for use by the hawk drive read/write emulation. Port B is for
// use by the storage implementation.
// This uses 2**18 bits of RAM (262Kb). FPGAs without this much ram will
// either need an external ram or a streaming storage implementation.
// The ram has room for 512 bytes per sector, but only the first 402 should be used
// (400 for data, 2 for checksum).
module CylinderCache (
	output reg [7:0] q_a, q_b,
	input [7:0] data_a, data_b,
	input [14:0] addr_a, addr_b, // addr[14:13] is head, addr[12:9] is sector
	input we_a, we_b,
    input clk_a, clk_b,
);

reg [7:0] ram[2**15:0];

// Port A 
always @ (posedge clk_a)
begin
    if (we_a) 
    begin
        ram[addr_a] = data_a;
    end
    q_a <= ram[addr_a];
end 

// Port B 
always @ (posedge clk_b)
begin
    if (we_b) 
    begin
        ram[addr_b] = data_b;
    end
    q_b <= ram[addr_b];
end
    
endmodule