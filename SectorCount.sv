module SectorCount (
    input wire clk25, // 2.5 MHz
    input wire reset,
    output wire index_strobe,
    output wire sector_strobe,
    output reg[4:0] sector
);

reg [11:0] counter;
wire next_sector;

assign sector_strobe = ~reset && (counter < 120);  // recordings show 48ns strobe
assign index_strobe = sector_strobe && (sector == 0);
assign next_sector = counter >= 3905;

always_ff @( posedge clk25 ) begin : counter_logic
    if (reset || next_sector)
        counter <= 0;
    else
        counter <= counter + 1;    
end

always_ff @( posedge clk25 ) begin : sector_logic
    if (reset) begin
        sector <= 0;
    end else if (next_sector) begin
        sector[4] <= 0;
        sector[3:0] <= sector[3:0] + 1;
    end else begin
        sector <= sector;
    end
end


endmodule