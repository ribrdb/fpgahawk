// DirtySectors keeps track of which sectors still need to be flushed to storage.
// This implementation supports only one writer or flusher at a time.
// That's assuming that we'll just keep all writes to the same cylinder in cache
// and only flush to storage when seeking to another cylinder.
module DirtySectors (
    output reg[63:0] dirty_sectors,
    output wire all_clean,

    input wire clk,
    input wire reset_n,
    input wire en,  // Make sure en is 0 while switching clocks
    input wire[5:0] saddr,
    input wire d // 0 for clean, 1 for dirty
);

assign all_clean = ~|dirty_sectors;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        dirty_sectors <= 0;
    else 
        casez ({en,d})
            2'b0?: 
            dirty_sectors <= dirty_sectors;
            2'b10:
            dirty_sectors <= dirty_sectors & ~(1 << saddr);
            2'b11:
            dirty_sectors <= dirty_sectors | (1 << saddr);
        endcase 
end
    
endmodule