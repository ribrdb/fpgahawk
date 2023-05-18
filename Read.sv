module Read (
    input wire clk,
    input wire[1:0] hs,
    input wire[8:0] cyl,
    input wire[4:0] sect,
    input wire[7:0] data_in,
    input wire sector_strobe,
    input wire rd_en,

    output reg data_area,
    output reg[8:0] addr_out,
    output reg data_out,
    output reg prefetch
);

localparam ADDR_GAP = 3'd0, ADDR = 3'd1, DATA_GAP = 3'd2, DATA = 3'd3, END_GAP = 3'd4;
localparam ADDR_GAP_MAX = 12'd207, ADDR_MAX = 12'd31, DATA_GAP_MAX=12'd207, DATA_MAX=12'd3264 /* 408*8) */; 

reg[11:0] counter = 0;
reg[2:0] state = 0, next_state=0;
logic reset_counter;
reg[7:0] data_shift_reg;
reg[15:0] addr_shift_reg;

reg reading;

assign data_area = state >= DATA;

always_comb begin : counter_reset_logic
    if (sector_strobe)
        reset_counter = 1;
    else
    case (state)
        ADDR_GAP:
            reset_counter = counter == ADDR_GAP_MAX;
        ADDR:
            reset_counter = counter == ADDR_MAX;
        DATA_GAP:
            reset_counter = counter == DATA_GAP_MAX;
        DATA:
            reset_counter = counter == DATA_MAX;
        default:
            reset_counter = 0;
    endcase
end

always_comb begin : next_state_logic
    if (sector_strobe)
        next_state = ADDR_GAP;
    else if (reset_counter)
    case (state)
        ADDR_GAP:
            next_state = ADDR;
        ADDR:
            next_state = DATA_GAP;
        DATA_GAP:
            next_state = DATA;
        DATA:
            next_state = END_GAP;
        default:
            next_state = ADDR_GAP;
    endcase
    else next_state = state;
end

always_ff @ (posedge clk) counter <= reset_counter ? 12'b0 : counter + 1'b1;
always_ff @ (posedge clk) state <= next_state;

always_ff @ (posedge clk) 
if (state == DATA)
    addr_out <= counter[2:0] == 0 ? addr_out + 1'b1 : addr_out;
else
    addr_out <= 0;

always_ff @ (posedge clk)
if (state == ADDR)
    addr_shift_reg <= {1'b0,addr_shift_reg[15:1]};
else
    addr_shift_reg <= {hs, cyl, sect};

always_ff @ (posedge clk)
if (state == DATA)
    data_shift_reg <= &counter[2:0] ? data_in : {data_shift_reg[6:0],{1'b0}};
else
    data_shift_reg <= data_in;

always_ff @ (posedge clk)
case (state)
    ADDR_GAP:
    data_out <= counter == ADDR_GAP_MAX;
    ADDR:
    data_out <= addr_shift_reg[0];
    DATA_GAP:
    data_out <= counter == DATA_GAP_MAX;
    DATA:
    data_out <= data_shift_reg[7];
    default:
    data_out <= 0;
endcase

always_ff @ (posedge clk) begin
    reading <= rd_en;
    prefetch <= rd_en && !reading && state <= ADDR;
end


endmodule