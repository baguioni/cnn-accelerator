module sram #(
    parameter int DEPTH = 64,
    parameter int SRAM_WIDTH = 64
) (
    input logic i_clk, i_nrst,
    // Control signals
    input logic i_active_low_en, 
    input logic i_read_write_en, // 0: Read, 1: Write
    input logic [SRAM_WIDTH-1:0] i_write_bitmask,
    // Data signals
    input logic [SRAM_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_addr,
    output logic [SRAM_WIDTH-1:0] o_data_out
);
    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [SRAM_WIDTH-1:0] sram [DEPTH-1:0];

    initial begin
        $monitor("[%0t] [SRAM] activeLowEn=%0b readWriteEn=%0b writeBitmask=0x%0h dataIn=0x%0h addr=%0d dataOut=0x%0h",
            $time, i_active_low_en, i_read_write_en, i_write_bitmask, i_data_in, i_addr, o_data_out);
    end

    // Read data
    always_ff @(posedge i_clk) begin
        if (~i_active_low_en) begin
            if (~i_read_write_en) begin
                o_data_out <= sram[i_addr];
            end
        end
    end

    // Write data
    always_ff @(posedge i_clk) begin
        if (~i_active_low_en) begin
            if (i_read_write_en) begin
                for (int i = 0; i < SRAM_WIDTH; i += 8) begin
                    if (i_write_bitmask[i]) begin
                        sram[i_addr][i +: 8] <= i_data_in[i +: 8];
                    end
                end
            end
        end
    end
endmodule