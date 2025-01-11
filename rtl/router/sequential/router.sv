module router #(
    parameter int ROUTER_COUNT = 4,
    parameter int SRAM_DATA_WIDTH = 64,
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_reg_clear,

    // Control signals
    input logic i_ag_en, i_ac_en, i_miso_pop_en,

    // Address generator related signals
    input logic [ROUTER_COUNT-1:0][ADDR_WIDTH-1:0] i_o_x, i_o_y, 
    input logic [ADDR_WIDTH-1:0] i_i_size, i_start_addr,

    // Address comparator related signals
    input logic [SRAM_DATA_WIDTH-1:0] i_data,
    input logic [ADDR_WIDTH-1:0] i_addr,
    input logic i_data_valid,

    output logic [ROUTER_COUNT-1:0][DATA_WIDTH-1:0] o_data
);

    // row router popping logic
    logic [ROUTER_COUNT-1:0] counter;
    logic [ROUTER_COUNT-1:0] rr_pop_en;
    logic [ROUTER_COUNT-1:0] rr_empty;

    always_ff @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            rr_pop_en <= 0;
            counter <= 0;
        end else begin
            if (i_reg_clear) begin
                rr_pop_en <= 0;
                counter <= 0;
            end else if (i_miso_pop_en) begin
                for (int i = 0; i < ROUTER_COUNT; i = i + 1) begin
                    if (counter >= i) begin
                        rr_pop_en[i] <= 1;
                    end else begin
                        rr_pop_en[i] <= 0;
                    end 
                end

                if (counter != ROUTER_COUNT) begin
                    counter <= counter + 1;
                end
            end
        end
    end

    // row router instances
    genvar ii;
    generate
        for (ii = 0; ii < ROUTER_COUNT; ii = ii + 1) begin : router_inst
            row_router #(
                .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .INDEX(ii)
            ) row_router_inst (
                .i_clk(i_clk),
                .i_nrst(i_nrst),
                .i_reg_clear(i_reg_clear),
                .i_ag_en(i_ag_en),
                .i_ac_en(i_ac_en),
                .i_miso_pop_en(rr_pop_en[ii]),
                .i_o_x(i_o_x[ii]),
                .i_o_y(i_o_y[ii]),
                .i_i_size(i_i_size),
                .i_start_addr(i_start_addr),
                .i_data(i_data),
                .i_data_valid(i_data_valid),
                .i_addr(i_addr),
                .o_data(o_data[ii]),
                .o_miso_empty(rr_empty[ii]),
                .o_valid()
            );
        end
    endgenerate


endmodule