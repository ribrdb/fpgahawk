// FakeDSK sends commands to the Hawk so you can test without a DSK
// controller.
module FakeDSK (
    input wire clk, // writes will be 1/4 this, so should be ~10MHz
    input wire [14:0] addr,
    input wire [1:0] cmd, // 1 = seek, 2 == read, 3 = write
    input wire [1:0] size, // 0 = sector, 1 = track, 2 = cylinder, 3 = whole disk,

    output reg hawk_cyl_strobe,
    output reg [8:0] hawk_cylad,
    //output reg hawk_rtzs,
    output reg [1:0] hawk_hs,
    output reg hawk_wr_data,
    output reg hawk_wr_en,
    output reg hawk_read_en,
    //output reg hawk_unit_select,

    input wire hawk_on_cyl,
    input wire hawk_interrupt,
    input wire hawk_rd_data,
    input wire hawk_rd_clock,
    input wire hawk_index,
    input wire hawk_sector,
    input wire hawk_seek_err,
    input wire hawk_adint,
    input wire hawk_fault,
    input wire hawk_ready,
    input wire hawk_wrstat,
    input wire [4:0] hawk_sa,
    input wire hawk_addr_ack,
    input wire hawk_density
);

localparam SEEK_CMD = 2'd3, READ_CMD = 2'd2, WRITE_CMD = 2'd3;

localparam IDLE = 4'd0, SEEK = 4'd1, SECTOR_WAIT = 4'd2, WRITE_GAP = 4'd3, READ = 4'd4, WRITE = 4'd5, WRITE_PREP = 4'd6, READ_ADDR = 4'd7, DELAY = 4'd8;

logic [3:0] state, next_state;
logic [1:0] active_cmd = 0;
logic [14:0] cur_addr;
logic sect_stb0, sect_stb1, sect_stb2, sect_stb;
logic [15:0] read_addr, read_addr_buf;
logic [7:0] read_data, read_data_buf;

logic new_read_addr, new_read_addr0, new_read_addr1, new_read_addr2;
logic new_read_data, new_read_data0, new_read_data1, new_read_data2;
logic found_sync_bit;
logic [3:0] read_bit_count;
logic [4:0] delay;
logic [7:0] addr_pat;
logic [8:0] byte_addr;
logic [14:0] end_sector;
logic [14:0] next_addr;
logic [8:0] next_cyladdr;
logic [8:0] req_cyladdr;
logic [13:0] write_cnt;
logic [7:0] write_buf;

reg [7:0] ram[511:0];

assign next_addr = cur_addr + 1'b1;
assign hawk_hs = cur_addr[5:4];
assign hawk_cylad = cur_addr[14:6];
assign next_cyladdr = next_addr[14:6];
assign req_cyladdr = addr[14:6];
assign sect_stb = sect_stb1 ^ sect_stb2;
assign new_read_addr = new_read_addr1 ^ new_read_addr2;
assign new_read_data = new_read_data1 ^ new_read_data2;
assign addr_pat = cur_addr[14:8] ^ cur_addr[7:0];
assign hawk_wr_en = (state == WRITE_GAP || state == WRITE);

always @(posedge clk) hawk_read_en <= (state == READ_ADDR || state == READ);

always @(posedge hawk_sector) sect_stb0 <= ~sect_stb0;

always @(posedge clk) begin
    sect_stb1 <= sect_stb0;
    sect_stb2 <= sect_stb1;
    new_read_addr1 <= new_read_addr0;
    new_read_addr2 <= new_read_addr1;
    new_read_data1 <= new_read_data0;
    new_read_data2 <= new_read_data1;
end

always_ff @(posedge clk) begin : seek_logic
    hawk_cyl_strobe <= (state == SEEK) && hawk_ready;
end

always_ff @(posedge clk)
case (state)
    DELAY: delay <= delay - 1'b1;
    READ_ADDR: delay <= 5'h1F;
    default: delay <= 0;
endcase

always_comb begin
    case (state)
    IDLE: begin
        case (cmd)
            0: next_state = IDLE;
            1: next_state = SEEK;
            2: next_state = (req_cyladdr == hawk_cylad) ? SECTOR_WAIT : SEEK;
            3: next_state = (req_cyladdr == hawk_cylad) ? WRITE_PREP : SEEK;
        endcase
    end
    SEEK:
        if (hawk_ready)
            case (active_cmd)
                READ_CMD: next_state = SECTOR_WAIT;
                WRITE_CMD: next_state = WRITE_PREP; 
                default: 
                next_state = IDLE;
            endcase
        else
            next_state = SEEK;
    SECTOR_WAIT:
        if (hawk_on_cyl && sect_stb && hawk_sa == cur_addr[3:0])
            next_state = READ_ADDR;
        else
            next_state = SECTOR_WAIT;
    READ_ADDR:
        next_state = new_read_addr ? DELAY : READ_ADDR;
    DELAY:
        if (delay == 0)
        case (active_cmd)
            READ_CMD: next_state = READ;
            WRITE_CMD: next_state = WRITE_GAP;
				default: next_state = IDLE;
        endcase
		  else next_state = DELAY;
    WRITE_PREP:
        next_state = (byte_addr == 402) ? SECTOR_WAIT : WRITE_PREP;
    READ:
        if (byte_addr == 402)
            casez ({end_sector == cur_addr, next_cyladdr == hawk_cylad})
                2'b1?: next_state = IDLE;
                2'b01: next_state = SECTOR_WAIT;
                2'b00: next_state = SEEK;
            endcase
        else
            next_state = READ;
    WRITE:
        if (byte_addr == 402)
            casez ({end_sector == cur_addr, next_cyladdr == hawk_cylad})
                2'b1?: next_state = IDLE;
                2'b01: next_state = WRITE_PREP;
                2'b00: next_state = SEEK;
            endcase
        else
            next_state = WRITE;
    WRITE_GAP:
        if (write_cnt == {12'd207,2'b11}) next_state = WRITE;
        else next_state = WRITE_GAP;
    endcase
end

function [7:0] shift_read_data(input[7:0] sr, input data);
    shift_read_data = {sr[6:0], data};
endfunction

function [15:0] shift_read_addr(input [15:0] sr, input data);
    shift_read_addr = {data, sr[15:1]};
endfunction

always_ff @(posedge clk) state <= next_state;

always_ff @(posedge clk) begin
    if (state == IDLE && cmd != 0) begin
        active_cmd <= cmd;
        cur_addr <= addr;
        end_sector <= calc_end_sector(addr, size);
    end else begin
        active_cmd <= active_cmd;
        cur_addr <= (byte_addr == 402 && state != WRITE_PREP) ? next_addr : cur_addr;
        end_sector <= end_sector;
    end
end

function [14:0] calc_end_sector(input[14:0] addr, input[1:0] size);
begin
    case (size)
        0: calc_end_sector = addr;
        1: calc_end_sector = {addr[14:4], 4'hf};
        2: calc_end_sector = {addr[14:6], 2'b11, 4'hf};
        3: calc_end_sector = {9'd407, 2'b11, 4'hf};
    endcase
end
endfunction

always_ff @(posedge clk) begin
    case (state)
        WRITE_PREP: byte_addr <= byte_addr + 1'b1;
        READ: byte_addr <= new_read_data ? byte_addr + 1'b1 : byte_addr;
        WRITE: byte_addr <= write_cnt[13:5];
        default: byte_addr <= 0;
    endcase
end

always_ff @(posedge clk) begin
    if (state == WRITE_PREP) ram[byte_addr] = addr_pat ^ byte_addr[7:0] ^ byte_addr[8];
    else if (state == READ && new_read_data) ram[byte_addr] = read_data;
end

always_ff @(posedge clk) begin
    if (state == WRITE || state == WRITE_GAP) begin
        write_cnt <= write_cnt + 1'b1;
        casez (write_cnt[1:0])
            2'b00: begin
                hawk_wr_data <= 1'b1;
            end
            2'b10: begin
                hawk_wr_data <= write_buf[7];
            end
            2'b?1: begin
                hawk_wr_data <= 0;
            end
        endcase
    end else begin
        write_cnt <= 0;
        hawk_wr_data <= 0;
    end
end

always_ff @(posedge clk) begin
    if (state == WRITE && write_cnt[1:0] == 2'b01) begin
       write_buf <= (write_cnt[4:2] == 0) ? ram[byte_addr] : {write_buf[7:1],1'b0};
    end else if (state == WRITE_GAP && write_cnt[13:2]==12'd207)
        write_buf <= 8'hff;
    else
        write_buf <= write_buf;
end

always_ff @(posedge hawk_rd_clock or negedge hawk_read_en) begin
    if (!hawk_read_en) begin
        found_sync_bit <= 0;
        read_addr <= read_addr;
        read_data <= read_data;
        read_addr_buf <= 0;
        read_data_buf <= 0;
        read_bit_count <= 0;	
	 end else if (!found_sync_bit) begin
        found_sync_bit <= hawk_rd_data;
        read_addr <= read_addr;
        read_data <= read_data;
        read_addr_buf <= 0;
        read_data_buf <= 0;
        read_bit_count <= 0;
    end else begin
        found_sync_bit <= 1;
        read_addr <= (read_bit_count == 4'hF) ? shift_read_addr(read_addr_buf, hawk_rd_data) : read_addr;
        read_data <= (read_bit_count == 4'h7) ? shift_read_data(read_data_buf, hawk_rd_data) : read_data;
        read_addr_buf <= shift_read_addr(read_addr_buf, hawk_rd_data);
        read_data_buf <= shift_read_data(read_data_buf, hawk_rd_data);
        read_bit_count <= read_bit_count + 1'b1;
    end
end

always_ff @(posedge hawk_rd_clock) begin
    if (read_bit_count == 4'h7)
        new_read_data0 = ~new_read_data0;
    if (read_bit_count == 4'hF)
        new_read_addr0 = ~new_read_addr0;
end
    

endmodule