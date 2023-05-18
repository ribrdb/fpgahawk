module Hawk #(
    parameter DENSITY = 1'b1 // not really sure if this should be 0 or 1
) (
    input wire clk,
    input wire sd_clk, // 25 MHz
    input wire data_clk, // 2.5 MHz
    input wire i_cyl_strobe,
    input wire[8:0] cylad,
    input wire i_rtzs,
    input wire [1:0] hs,
    input wire wr_data,
    input wire i_wr_en,
    // input i_wire er_en, 
    input wire i_read_en,
    // input wire stop_ov,
    input wire unit_select,
    // input wire write_prot,
    input wire sd_miso,

    output wire o_on_cyl,
    output wire interrupt,
    output wire o_rd_data,
    output wire o_rd_clock,
    output wire o_index,
    output wire o_sector,
    output wire o_seek_err,
    output wire o_adint,
    output wire o_fault,
    output wire o_ready,
    output wire o_wrstat,
    output wire [4:0] o_saddr,
    output wire o_addr_ack,
    output wire o_density,

    output wire sd_cs,
    output wire sd_mosi,
    output wire sd_sclk
);

logic select_reg;
logic reading;
logic on_cyl;
logic rd_data;
logic rd_clock;
logic index;
logic sector;
logic seek_err;
logic adint;
logic fault;
logic ready;
logic addr_ack;
logic density;

logic wr_en;
logic read_en;

logic seek_ready;
logic [8:0] hawk_cache_addr;
logic [7:0] hawk_cache_rd_data;
logic [7:0] hawk_cache_wr_data;
logic hawk_cache_wr_en;
logic [8:0] sd_cache_addr;
logic [7:0] sd_cache_rd_data;
logic [7:0] sd_cache_wr_data;
logic sd_cache_wr_en;
logic [4:0] sector_addr;
logic sd_rd;
logic sd_wr;
logic sd_ready;
logic sd_error;
logic [8:0] seek_cyl;
logic [8:0] read_addr_out;
logic data_area;
logic sep_data;
logic new_data;
logic [8:0] write_addr_out;

assign o_on_cyl = select_reg ? on_cyl : 1'bZ;
assign o_rd_data = reading ? rd_data : 1'bZ;
assign o_rd_clock = reading ? data_clk : 1'bZ;
assign o_index = select_reg ? index : 1'bZ;
assign o_sector = select_reg ? sector : 1'bZ;
assign o_seek_err = select_reg ? seek_err : 1'bZ;
assign o_adint = select_reg ? adint : 1'bZ;
assign o_fault = select_reg ? fault : 1'bZ;
assign o_ready = select_reg ? ready : 1'bZ;
assign o_wrstat = select_reg ? 1'b0 : 1'bZ;
assign o_saddr = select_reg ? sector_addr : 5'bZZZZZ;
assign o_addr_ack = select_reg ? addr_ack : 1'bZ;
assign o_density = select_reg ? DENSITY : 1'bZ;  

assign wr_en = i_wr_en & unit_select;
assign read_en = i_read_en & unit_select;

assign interrupt = seek_err | adint | on_cyl;
assign fault = sd_error;

assign hawk_cache_addr = wr_en ? write_addr_out : read_addr_out;

always_ff @(negedge clk) select_reg <= unit_select;
always_ff @(negedge clk) reading <= read_en;

always_ff @(posedge clk) ready <= ready ? 1'b1 : (sd_ready && on_cyl);

SingleSectorCache cache0(
    .clk_a(clk),
    .addr_a(hawk_cache_addr),
    .din_a(hawk_cache_wr_data),
    .wr_en_a(hawk_cache_wr_en),
    .dout_a(hawk_cache_rd_data),

    .clk_b(sd_clk),
    .addr_b(sd_cache_addr),
    .din_b(sd_cache_wr_data),
    .wr_en_b(sd_cache_wr_en),
    .dout_b(sd_cache_rd_data)
);

SdCache sd0 (
    .clk(sd_clk),
    .hadr(hs),
    .cadr(cylad),
    .sadr(sector_addr),
    .reset(1'b0),
    .rd_start(sd_rd),
    .wr_start(sd_wr),

    .cs(sd_cs),
    .mosi(sd_mosi),
    .miso(sd_miso),
    .sclk(sd_sclk),
    .ready(sd_ready),
    .error(sd_error),

    .cache_addr(sd_cache_addr),
    .cache_din(sd_cache_rd_data),
    .cache_dout(sd_cache_wr_data),
    .cache_wr(sd_cache_wr_en)
);

SeekController #(.MIN_SEEK_CYCLES(1000), .ACK_CYCLES(90)) seek0(
    .clk(clk),
    .en(unit_select),
    .cyl_strobe(i_cyl_strobe),
    .cyl_addr_in(cylad),
    .rtzs(i_rtzs),
    .cyl_addr_out(seek_cyl),
    .error(seek_err),
    .invalid_addr(adint),
    .addr_ack(addr_ack),
    .on_cyl(on_cyl)
);

SectorCount sector0(
    .clk2_5(data_clk),
    .en(on_cyl && sd_ready),
    .index_strobe(index),
    .sector_strobe(sector),
    .sector(sector_addr)
);

Read read0(
    .clk(data_clk),
    .hs(hs),
    .cyl(seek_cyl),
    .sect(sector_addr),
    .data_in(hawk_cache_rd_data),
    .sector_strobe(sector),
    .rd_en(read_en),
    .data_area(data_area),
    .addr_out(read_addr_out),
    .data_out(rd_data),
    .prefetch(sd_rd)
);

DataSeparator #(
    .CLOCK_WINDOW_START(35),
    .CLOCK_WINDOW_END(45),
    .DATA_WINDOW_START(10),
    .DATA_WINDOW_END(30)
)
sep0 (
    .wr_clock(new_data),
    .wr_data(sep_data),
    .hf_clk(clk),
    .en(wr_en),
    .dsk_wr_data_clk(wr_data)
);

Write wr0
(
    .clk(clk),
    .wr_data(sep_data),
    .new_data(new_data),
    .data_area(data_area),
    .addr_out(write_addr_out),
    .data_out(hawk_cache_wr_data),
    .wr_en(hawk_cache_wr_en),
    .wr_flush(sd_wr)
);
endmodule