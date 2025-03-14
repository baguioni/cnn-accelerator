// Will have to add a control module to handle timing of operations
// Or perhaps higher level operation does this and just waits for done signals
// of each operation so that it can be timed with weight router
module input_router #(
    parameter int DATA_WIDTH = 8,
    parameter int SPAD_DATA_WIDTH = 64,
    parameter int SPAD_N = SPAD_DATA_WIDTH / DATA_WIDTH,
    parameter int ADDR_WIDTH = 8,
    parameter int ROWS = 4,
    parameter int MISO_DEPTH = 16,
    parameter int MPP_DEPTH = 16,
    // This is for 3x3 kernel
    // Might remove this in the future
    parameter int ADDR_LENGTH = 9 
)(
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic [1:0] i_p_mode,
    input logic i_spad_write_en, 

    // SRAM input signals
    input logic [SPAD_DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,

    // Tile Reader Control signals
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_addr_end,
    output logic o_read_done, o_done,

    // Address Generator Control signals
    input logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride,
    input logic [ADDR_WIDTH-1:0] i_i_c_size, i_i_c,

    output logic [ROWS-1:0][DATA_WIDTH-1:0] o_data,
    output logic [ROWS-1:0] o_data_valid,

    // Upper level control signals
    input logic i_pop_en,
    output logic o_ready, o_context_done, o_output_done
);
    // SPAD related signals
    logic [SPAD_DATA_WIDTH-1:0] spad_data_out;
    logic spad_data_out_valid;
    logic [ADDR_WIDTH-1:0] spad_read_addr, tr_data_addr;
    logic spad_read_en, tr_valid_addr;

    // Controller related signals
    logic [ROWS-1:0] row_id, router_row_id;
    logic [ADDR_WIDTH-1:0] o_x, o_y;
    logic ag_en, ac_en, tile_read_en, pop_en, router_reg_clear;

    // Address Generator related signals
    logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] ag_addr;
    logic ag_valid;

    logic [2:0] state;

    // Row Group related signals
    logic router_addr_empty, router_data_empty;

    spad #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SPAD_DATA_WIDTH)
    ) input_sram (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_write_en(i_spad_write_en),
        .i_read_en(spad_read_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_read_addr(spad_read_addr),
        .o_data_out(spad_data_out),
        .o_data_out_valid(spad_data_out_valid)
    );

    tile_reader #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) tile_reader_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_read_en(tile_read_en),
        .i_reg_clear(router_reg_clear),
        .i_start_addr(i_start_addr),
        .i_addr_end(i_addr_end),
        .o_buf_read_en(spad_read_en),
        .o_read_done(o_read_done),
        .o_valid_addr(tr_valid_addr),
        .o_read_addr(spad_read_addr),
        .o_data_addr(tr_data_addr)
    );

    ir_controller #(
        .ROWS(ROWS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) controller (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_pop_en(i_pop_en),
        .i_start_addr(i_start_addr),
        .i_o_size(i_o_size),
        .i_stride(i_stride),
        .o_row_id(row_id),
        .o_o_x(o_x),
        .o_o_y(o_y),
        .o_ag_en(ag_en),
        .o_ac_en(ac_en),
        .o_tile_read_en(tile_read_en),
        .o_pop_en(pop_en),
        .i_addr_empty(router_addr_empty),
        .i_data_empty(router_data_empty),
        .o_done(o_output_done),
        .o_reg_clear(router_reg_clear),
        .o_ready(o_ready),
        .o_context_done(o_context_done),
        .o_state(state)
    );

    address_generator #(
        .ROWS(ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ADDR_LENGTH(ADDR_LENGTH)
    ) address_gen (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(ag_en),
        .i_reg_clear(router_reg_clear),
        .i_o_x(o_x),
        .i_o_y(o_y),
        .i_i_c(i_i_c),
        .i_i_size(i_i_size),
        .i_i_c_size(i_i_c_size),
        .i_start_addr(i_start_addr),
        .o_valid(ag_valid),
        .o_addr(ag_addr),
        .i_row_id(row_id),
        .o_row_id(router_row_id)
    );

    /*
        When routing data.

            When reading from tile and all the data has been fetched
                o_addr_empty will be high
            When all the data has been pushed from the router
                o_data_empty will be high

    */
    row_group #(
        .ROWS(ROWS),
        .SPAD_DATA_WIDTH(SPAD_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_LENGTH(ADDR_LENGTH),
        .SPAD_N(SPAD_N),
        .MISO_DEPTH(MISO_DEPTH),
        .MPP_DEPTH(MPP_DEPTH)
    ) row_group (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(router_reg_clear),
        .i_ag_en(ag_en),
        .i_ac_en(ac_en),
        .i_miso_pop_en(pop_en & i_pop_en), // originally pop_en
        .i_p_mode(i_p_mode),
        .i_ag_addr(ag_addr),
        .i_ag_valid(ag_valid),
        .i_row_id(router_row_id),
        .i_data(spad_data_out),
        .i_addr(tr_data_addr),
        .i_data_valid(spad_data_out_valid),
        .o_data(o_data),
        .o_data_valid(o_data_valid),
        .o_data_empty(router_data_empty),
        .o_addr_empty(router_addr_empty)
    );

    assign o_done = pop_en;

endmodule