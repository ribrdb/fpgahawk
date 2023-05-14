module SeekController #(
    parameter MIN_SEEK_CYCLES = 25,
    parameter ACK_CYCLES = 2, // recordings show ~900 ns strobe
    parameter INVALID_ADDR_IS_SEEK_ERROR = 1,
    parameter SEEK_ERROR_ENDS_ON_CYL = 1
) (
    input wire clk,
    input wire cyl_strobe,
    input wire [8:0] cyl_addr_in,
    input wire rtzs,
    output reg [8:0] cyl_addr_out,
    output reg seek_strobe,
    output reg error,
    output reg invalid_addr,
    output reg addr_ack,
    output reg on_cyl
);

reg [$clog2(MIN_SEEK_CYCLES-1):0] counter = 0;
reg [8:0] addr_s0, addr_s1, addr_s2;
reg seek_s0, seek_s1, seek_s2;
wire on_cyl_mask;
wire new_addr_in;

assign new_addr_in = seek_s2 ^ seek_s1;
assign on_cyl_mask = ~(SEEK_ERROR_ENDS_ON_CYL & error);

always @(posedge rtzs or negedge cyl_strobe) begin
    if (rtzs) begin
        seek_s0 <= ~seek_s0;
        addr_s0 <= 0;
    end else begin
        seek_s0 <= ~seek_s0;
        addr_s0 <= cyl_addr_in;
    end
end

always @(posedge clk) addr_s1 <= addr_s0;
always @(posedge clk) addr_s2 <= addr_s1;
always @(posedge clk) seek_s1 <= seek_s0;
always @(posedge clk) seek_s2 <= seek_s1;

always @(posedge clk) begin
    if (new_addr_in) begin
        counter <= 0;
        if (addr_s2 > 407) begin
            seek_strobe <= 0;
            error <= INVALID_ADDR_IS_SEEK_ERROR;
            invalid_addr <= 1;
            addr_ack <= 0;
            cyl_addr_out <= cyl_addr_out;
            on_cyl <= 1'b?;
        end else begin
            seek_strobe <= 1;
            error <= 0;
            invalid_addr <= 0;
            addr_ack <= 1;
            cyl_addr_out <= addr_s2;
            on_cyl <= 0;
        end
    end else begin
        seek_strobe <= 0;
        counter <= counter + 1;
        error <= error;
        invalid_addr <= invalid_addr;
        cyl_addr_out <= cyl_addr_out;
        addr_ack <= addr_ack && (counter < ACK_CYCLES);
        on_cyl <= on_cyl_mask & (on_cyl || (counter >= MIN_SEEK_CYCLES-1));
    end
end
endmodule