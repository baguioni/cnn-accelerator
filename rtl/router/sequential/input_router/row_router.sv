module row_router #(
    parameter int SRAM_DATA_WIDTH = 64,
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_LENGTH = 9,
    parameter int ADDR_WIDTH = 8,
    parameter int KERNEL_SIZE = 3,
    parameter int PEEK_WIDTH = 8,
    parameter int INDEX = 0
) (
    input logic i_clk, i_nrst, i_reg_clear,

    // Control signals
    input logic i_mpp_write_en, i_ac_en, i_miso_pop_en,

    // Address generator related signals
    input [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] i_ag_addr,
    input logic i_ag_valid,

    // Address comparator related signals
    input logic [SRAM_DATA_WIDTH-1:0] i_data,
    input logic [ADDR_WIDTH-1:0] i_addr,
    input logic i_data_valid,

    // MISO FIFO related signals
    output logic [DATA_WIDTH-1:0] o_data,
    output logic o_miso_empty, o_valid,

    // MPP FIFO related signals
    output logic o_mpp_empty
);
    logic [PEEK_WIDTH-1:0] valid_data;

    // MISO - AC related signals
    logic [PEEK_WIDTH-1:0][DATA_WIDTH-1:0] peek_addr;
    logic [PEEK_WIDTH-1:0] peek_valid;

    mpp_fifo #(
        .DEPTH(9),
        .DATA_WIDTH(ADDR_WIDTH),
        .DATA_LENGTH(ADDR_LENGTH),
        .PEEK_WIDTH(PEEK_WIDTH)
    ) mpp_fifo (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(i_mpp_write_en),
        .i_data_in(i_ag_addr),
        .i_pop_en(ac_addr_hit[0]),
        .i_data_hit(ac_addr_hit),
        // .i_peek_en(i_peek_en),
        .o_peek_data(peek_addr),
        .o_peek_valid(peek_valid),
        .o_empty(o_mpp_empty),
        .o_full()
    );

    // Data to be sent to MPP
    logic [PEEK_WIDTH-1:0] ac_addr_hit;

    // Data to be stored in MISO
    logic [PEEK_WIDTH-1:0][DATA_WIDTH-1:0] ac_data_hit;

    address_comparator #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .PEEK_WIDTH(PEEK_WIDTH)
    ) address_comparator (
        .i_en(i_ac_en & i_data_valid),
        .i_data(i_data),
        .i_addr(i_addr),
        .i_peek_addr(peek_addr),
        .i_peek_valid(peek_valid),
        .o_addr_hit(ac_addr_hit),
        .o_data_hit(ac_data_hit)
    );

    miso_fifo #(
        .DEPTH(32),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(PEEK_WIDTH),
        .INDEX(INDEX)
    ) miso_fifo (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(ac_addr_hit[0]),
        .i_pop_en(i_miso_pop_en),
        .i_data(ac_data_hit),
        .i_valid(ac_addr_hit),
        .o_data(o_data),
        .o_empty(o_miso_empty),
        .o_full(),
        .o_pop_valid(o_valid)
    );

endmodule