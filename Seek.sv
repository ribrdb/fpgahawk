module SeekController #(
    parameter MIN_SEEK_CYCLES = 25,
    parameter ACK_CYCLES = 2, // recordings show ~900 ns strobe
    parameter INVALID_ADDR_IS_SEEK_ERROR = 1,
    parameter SEEK_ERROR_ENDS_ON_CYL = 1
) (
    input wire clk,
    input wire en,
    input wire rtzs,
    input wire cyl_strobe,
    input wire [8:0] cyl_addr_in,
    output reg [8:0] cyl_addr_out,
    output reg seek_strobe,
    output reg error,
    output reg invalid_addr,
    output reg addr_ack,
    output reg on_cyl
);

reg [$clog2(MIN_SEEK_CYCLES-1):0] counter = 0;
reg [8:0] seek_addr;
reg seek_s0 = 0, seek_s1, seek_s2;
reg rtzs_s0 = 0, rtzs_s1, rtzs_s2;
wire on_cyl_mask;
wire seek_req;

assign seek_req = seek_s2 ^ seek_s1;
assign rtz_req = rtzs_s2 ^ rtzs_s1;
assign on_cyl_mask = ~(SEEK_ERROR_ENDS_ON_CYL && error);

always @(negedge rtzs) 
    if (en)
        rtzs_s0 = ~rtzs_s0;

always @(posedge cyl_strobe) begin
    if (en) begin
        seek_s0 <= ~seek_s0;
        seek_addr <= cyl_addr_in;
    // end else begin
    //     seek_s0 <= seek_s0;
    //     addr_s0 <= addr_s0;
    end
end

always @(posedge clk) seek_s1 <= seek_s0;
always @(posedge clk) seek_s2 <= seek_s1;
always @(posedge clk) rtzs_s1 <= rtzs_s0;
always @(posedge clk) rtzs_s2 <= rtzs_s1;

always @(posedge clk) begin
    if (seek_req || rtz_req) begin
        counter <= 0;
        if (seek_addr > 407 && !rtz_req) begin
            seek_strobe <= 0;
            error <= |INVALID_ADDR_IS_SEEK_ERROR;
            invalid_addr <= 1;
            addr_ack <= 0;
            cyl_addr_out <= cyl_addr_out;
            on_cyl <= 1'b?;
        end else begin
            seek_strobe <= 1;
            error <= 0;
            invalid_addr <= 0;
            addr_ack <= 1;
            cyl_addr_out <= rtz_req ? 1'b0 : seek_addr;
            on_cyl <= 0;
        end
    end else begin
        seek_strobe <= 0;
        counter <= counter + 1'b1;
        error <= error;
        invalid_addr <= invalid_addr;
        cyl_addr_out <= cyl_addr_out;
        addr_ack <= addr_ack && (counter < ACK_CYCLES);
        on_cyl <= on_cyl_mask & (on_cyl || (counter >= MIN_SEEK_CYCLES-1));
    end
end
endmodule