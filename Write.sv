// Ignores address when formatting. Maybe we should verify that it's the format we expect?
module Write (
    input wire clk,
    input wire wr_data,
    input wire new_data,
    input wire data_area,
    output reg [8:0] addr_out,
    output reg [7:0] data_out,
    output reg wr_en,
    output reg wr_flush
);

reg [11:0] counter;
assign addr_out = counter[11:3];
reg need_flush = 0;

always_ff @ (posedge clk) begin
    wr_en <= &counter[2:0];
    if (data_area) begin
        counter <= new_data ? counter + 1'b1 : counter;
        need_flush <= 1;
        wr_flush <= 0;
    end else begin
        counter <= 0;
        wr_flush <= need_flush;
        need_flush <= 0;
    end
end

always_ff @ (posedge clk) begin
    if (new_data) begin
        data_out <= {data_out[6:0], 1'b1};
    end else begin
        data_out <= data_area ? data_out : 8'hFF;
    end
end

endmodule