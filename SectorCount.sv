module SectorCount (
    input wire clk2_5, // 2.5 MHz
    input en,
    output reg index_strobe,
    output reg sector_strobe,
    output reg[4:0] sector
);

reg [11:0] counter;
wire next_sector;
wire next_sector_strobe;
wire next_index_strobe;

assign next_sector_strobe = counter < 120;  // recordings show 48us strobe
assign next_index_strobe = next_sector_strobe && (sector == 0);
assign next_sector = counter >= 3905;

always_ff @(posedge clk2_5) sector_strobe <= en & next_sector_strobe;
always_ff @(posedge clk2_5) index_strobe <= en & next_index_strobe;

always_ff @( posedge clk2_5 ) begin : counter_logic
    if (next_sector)
        counter <= 0;
    else
        counter <= counter + 1'b1;    
end

always_ff @( posedge clk2_5 ) begin : sector_logic
    if (next_sector) begin
        sector[4] <= 0;
        sector[3:0] <= sector[3:0] + 1'b1;
    end else begin
        sector <= sector;
    end
end


endmodule