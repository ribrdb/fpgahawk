module SingleSectorCache (
    input wire clk_a,
    input wire [8:0] addr_a,
    input wire [7:0] din_a,
    input wire wr_en_a,
    output reg[7:0] dout_a,

    input wire clk_b,
    input wire [8:0] addr_b,
    input wire [7:0] din_b,
    input wire wr_en_b,
    output reg[7:0] dout_b
);

reg [7:0] data[511:0];

always @(posedge clk_a) begin
    dout_a <= data[addr_a];
    if (wr_en_a) begin
        dout_a <= din_a;
        data[addr_a] <= din_a;
    end
end

always @(posedge clk_b) begin
    dout_b <= data[addr_b];
    if (wr_en_b) begin
        dout_b <= dout_b;
        data[addr_b] <= din_b;
    end
end
    
endmodule