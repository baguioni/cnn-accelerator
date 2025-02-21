module address_comparator #(
    parameter int SRAM_WIDTH = 64,
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 8,
    parameter int PEEK_WIDTH = 4
) (
    input logic i_en,

    // Tile reader signals
    input logic [SRAM_WIDTH-1:0] i_data,
    input logic [ADDR_WIDTH-1:0] i_addr,

    // Fifo signals
    input logic [PEEK_WIDTH-1:0][ADDR_WIDTH-1:0] i_peek_addr,
    input logic [PEEK_WIDTH-1:0] i_peek_valid,

    output logic [PEEK_WIDTH-1:0] o_addr_hit,
    output logic [PEEK_WIDTH-1:0][DATA_WIDTH-1:0] o_data_hit
);
    localparam SRAM_N = SRAM_WIDTH / DATA_WIDTH; // Number of data in a SRAM word

    logic [0:SRAM_N-1][DATA_WIDTH-1:0] sram_data;
    logic [0:SRAM_N-1][ADDR_WIDTH-1:0] sram_addr;
    logic [PEEK_WIDTH-1:0][ADDR_WIDTH-1:0] peek_addr;
    logic [PEEK_WIDTH-1:0] peek_valid;

    // Format the SRAM data and addrSRAM_Ness
    // Addresses are generated by offsetting the base address by the index
    genvar ii;
    generate
        for (ii=0; ii < SRAM_N; ii++) begin
            assign sram_data[ii] = i_data[ii*DATA_WIDTH+:DATA_WIDTH];
            assign sram_addr[ii] = i_addr * ADDR_WIDTH + ii;
        end
    endgenerate

    genvar jj;
    generate
        for (jj=0; jj < PEEK_WIDTH; jj++) begin
            assign peek_addr[jj] = i_peek_addr[jj];
            assign peek_valid[jj] = i_peek_valid[jj];
        end
    endgenerate

    logic [PEEK_WIDTH-1:0] addr_hit [SRAM_N-1:0];
    logic [PEEK_WIDTH-1:0] f_addr_hit;
    logic [PEEK_WIDTH-1:0][DATA_WIDTH-1:0] data_hit, f_data_hit;

    always_comb begin
        if (i_en) begin
            for (int i = 0; i < SRAM_N; i++) begin
                for (int j = 0; j < PEEK_WIDTH; j++) begin
                    if ((sram_addr[i] == peek_addr[j]) & peek_valid[j]) begin
                        addr_hit[j][i] = 1;
                        data_hit[j] = sram_data[i];
                    end else begin
                        addr_hit[i][j] = 0;
                    end
                end
            end

            for (int j = 0; j < PEEK_WIDTH; j++) begin
                f_addr_hit[j] = | addr_hit[j];

                // // Not sure if this is needed
                // if (f_addr_hit[j]) begin
                //     f_data_hit[j] = data_hit[j];
                // end else begin
                //     f_data_hit[j] = 0;
                // end
            end


        end else begin
            for (int i = 0; i < PEEK_WIDTH; i++) begin
                addr_hit[i] = 0;
                data_hit[i] = 0;
            end
        end
    end
    assign o_addr_hit = f_addr_hit;
    assign o_data_hit = data_hit;

endmodule