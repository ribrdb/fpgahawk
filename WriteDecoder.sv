// WriteDecoder reads the serial output from DataSeparator.
// It parses the sync patterns and sector addresses and outputs the data on a bus.
module WriteDecoder (
    output reg data_available,
    output reg [15:0] saddr_out,
    output reg [7:0] data,
    input wire reset_n,      
    input wire need_address,    // true if we need to parse the address from the data stream
                                // (e.g. we're formatting the drive). False if we already read the
                                // sector address
    input wire [15:0] saddr_in, // sector address, when need_address is false
    input wire wr_clock,
    input wire wr_data,
);

reg [15:0] cnt;

enum int unsigned {WAIT_FOR_SYNC_1 = 0, READ_ADDR = 1, READ_ADDR_CHECK = 2,
           WAIT_FOR_SYNC_2 = 3, READ_DATA = 4} state, next_state;

always_comb begin : next_state_logic
	  next_state = WAIT_FOR_SYNC_2;
	  case(state)
		WAIT_FOR_SYNC_1: next_state = wr_data ? READ_ADDR : WAIT_FOR_SYNC_1;
		WAIT_FOR_SYNC_2: next_state = wr_data ? READ_DATA : WAIT_FOR_SYNC_2;
		READ_ADDR: next_state = (cnt == 15) ? READ_ADDR_CHECK : READ_ADDR;
        READ_ADDR_CHECK: next_state = (cnt == 15) ? WAIT_FOR_SYNC_2 : READ_ADDR_CHECK;
        READ_DATA: next_state = (cnt[15:3] == 402) ? WAIT_FOR_SYNC_1 : READ_DATA;
	  endcase
end
always_ff @(posedge wr_clock or negedge reset) begin
	  if(~reset)
		 state <= need_address ? WAIT_FOR_SYNC_1 : WAIT_FOR_SYNC_2;
	  else
		 state <= next_state;
end

always_ff @(posedge wr_clock or negedge reset) begin
	  if(~reset)
		 saddr_out <= need_address ? 0 : saddr_in;
	  else
		 saddr_out <= (state == READ_ADDR) ? {saddr_out[15:1], wr_data} : saddr_out;
end

always_ff @(posedge wr_clock) begin
    cnt <= (state == WAIT_FOR_SYNC_1 || state == WAIT_FOR_SYNC_2) ? 0 : cnt + 1;
end

always_ff @(posedge wr_clock) begin
    if (state == READ_DATA) {
        data <= {data[7:1], wr_data};
        data_available <= cnt[2:0] == 7;
    } else {
        data_available <= 0;
        data <= 0;
    }
end

endmodule