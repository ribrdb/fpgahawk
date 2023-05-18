module SdCache (
    input wire clk, // 25 MHz
    input wire [1:0] hadr,
    input wire [8:0] cadr,
    input wire [4:0] sadr,
    input wire reset,
    input wire rd_start,
    input wire wr_start,

    output wire cs,
    output wire mosi,
    input wire miso,
    output wire sclk,
    output wire ready,
    output reg error,

    output reg [8:0] cache_addr,
    input wire [7:0] cache_din,
    output reg [7:0] cache_dout,
    output reg cache_wr
);

wire [31:0] address;

assign address = {5'b0, hadr, cadr, sadr, 11'b0};
assign error = ~ready && (rd_start | wr_start);
logic byte_available;
logic ready_for_next_byte;

sd_controller sd0(
    .cs(cs),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .rd(rd_start),
    .dout(cache_dout),
    .byte_available(byte_available),
    .wr(wr_start),
    .din(cache_din),
    .ready_for_next_byte(ready_for_next_byte),
    .reset(reset),
    .ready(ready),
    .address(address),
    .clk(clk)
);

always @(posedge clk) begin
    if (ready) begin
        cache_addr <= 0;
        cache_wr <= 0;
    end else begin
        cache_wr <= byte_available;
        cache_addr <= (ready_for_next_byte | byte_available) ? cache_addr + 1'b1 : cache_addr;
    end
end

endmodule