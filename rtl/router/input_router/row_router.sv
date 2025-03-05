module row_router #(
    parameter int SPAD_DATA_WIDTH = 64,
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_LENGTH = 9,
    parameter int ADDR_WIDTH = 8,
    parameter int KERNEL_SIZE = 3,
    parameter int SPAD_N = SPAD_DATA_WIDTH / DATA_WIDTH,
    parameter int MISO_DEPTH = 16,
    parameter int MPP_DEPTH = 16,
    parameter int INDEX = 0
) (
    input logic i_clk, i_nrst, i_reg_clear,

    // Control signals
    input logic i_mpp_write_en, i_ac_en, i_miso_pop_en,

    // Address generator related signals
    input [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] i_ag_addr,
    input logic i_ag_valid,

    // Address comparator related signals
    input logic [SPAD_DATA_WIDTH-1:0] i_data,
    input logic [ADDR_WIDTH-1:0] i_addr,
    input logic i_data_valid,

    // MISO FIFO related signals
    input logic [1:0] i_p_mode,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic o_miso_empty, o_valid,

    // MPP FIFO related signals
    output logic o_mpp_empty
);
    logic [SPAD_N-1:0] valid_data;

    // MISO - AC related signals
    logic [SPAD_N-1:0][DATA_WIDTH-1:0] peek_addr;
    logic [ADDR_WIDTH-1:0] ac_peek_addr [SPAD_N-1:0];
    logic [SPAD_N-1:0] peek_valid;
    
    // Data to be sent to MPP
    logic [SPAD_N-1:0] ac_addr_hit;

    // Data to be stored in MISO
    logic [SPAD_N-1:0][DATA_WIDTH-1:0] ac_data_hit;

    genvar i;
    generate
        for (i = 0; i < SPAD_N; i++) begin
            assign ac_peek_addr[i] = peek_addr[i];
        end
    endgenerate

    mpp_fifo #(
        .DEPTH(MPP_DEPTH),
        .DATA_WIDTH(ADDR_WIDTH),
        .DATA_LENGTH(ADDR_LENGTH),
        .PEEK_WIDTH(SPAD_N)
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


    address_comparator #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .PEEK_WIDTH(SPAD_N)
    ) address_comparator (
        .i_en(i_ac_en & i_data_valid),
        .i_data(i_data),
        .i_addr(i_addr),
        .i_peek_addr(ac_peek_addr),
        .i_peek_valid(peek_valid),
        .o_addr_hit(ac_addr_hit),
        .o_data_hit(ac_data_hit)
    );

    miso_fifo #(
        .DEPTH(MISO_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(SPAD_N),
        .INDEX(INDEX)
    ) miso_fifo (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(ac_addr_hit[0]),
        .i_pop_en(i_miso_pop_en),
        .i_p_mode(i_p_mode),
        .i_data(ac_data_hit),
        .i_valid(ac_addr_hit),
        .o_data(o_data),
        .o_empty(o_miso_empty),
        .o_full(),
        .o_pop_valid(o_valid)
    );

endmodule