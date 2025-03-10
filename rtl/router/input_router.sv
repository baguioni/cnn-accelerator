module input_router #(
    parameter int DATA_WIDTH = 8,
    parameter int SPAD_DATA_WIDTH = 64,
    parameter int SPAD_N = SPAD_DATA_WIDTH / DATA_WIDTH,
    parameter int ADDR_WIDTH = 8,
    parameter int ROWS = 4,
    parameter int MISO_DEPTH = 16
)(
    input logic i_clk,
    input logic i_nrst,
    input logic i_en,
    input logic i_reg_clear,
    input logic i_fifo_pop_en,

    // Precision mode - 0: 8x8, 1: 4x4: 2: 2x2
    input logic [1:0] i_p_mode,

    // Convolution mode - 0: PWise, 1: DWise
    input logic i_conv_mode,

    // Activation related signals
    input logic [ADDR_WIDTH-1:0] i_i_size,
    input logic [ADDR_WIDTH-1:0] i_o_size,
    input logic [ADDR_WIDTH-1:0] i_stride,
    input logic [ADDR_WIDTH-1:0] i_i_c_size,
    input logic [ADDR_WIDTH-1:0] i_i_c, // Which channel - For DWise

    // SPAD related signals
    input logic i_spad_write_en,
    input logic [SPAD_DATA_WIDTH-1:0] i_spad_data_in,
    input logic [ADDR_WIDTH-1:0] i_spad_write_addr,

    // Tile Reader related signals
    input logic [ADDR_WIDTH-1:0] i_start_addr,
    input logic [ADDR_WIDTH-1:0] i_addr_end,
    output logic o_read_done,

    // Output signals
    output logic [ROWS-1:0][DATA_WIDTH-1:0] o_data,
    output logic [ROWS-1:0] o_data_valid,

    // Status signals
    output logic o_ready,
    output logic o_context_done,
    output logic o_output_done,
    output logic o_done
);
    // SPAD related signals
    // We will move this to top level module
    logic [SPAD_DATA_WIDTH-1:0] spad_data_out;
    logic spad_data_out_valid;
    logic [ADDR_WIDTH-1:0] spad_read_addr;
    logic spad_read_en;

    // Tile Reader related signals
    // Forward this to routers
    logic [ADDR_WIDTH-1:0] tr_addr;
    logic [SPAD_DATA_WIDTH-1:0] tr_data;
    logic tr_data_valid;

    // Controller to Router and Tile Reader
    logic route_en, reg_clear;

    // Controller to Router Array
    logic [ROWS-1:0] id;
    logic [ADDR_WIDTH-1:0] start_addr, end_addr;
    logic addr_write_en, fifo_pop_en, fifo_pop_ready, fifo_empty;


    spad #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SPAD_DATA_WIDTH)
    ) input_spad (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_write_en(i_spad_write_en),
        .i_read_en(spad_read_en),
        .i_data_in(i_spad_data_in),
        .i_write_addr(i_spad_write_addr),
        .i_read_addr(spad_read_addr),
        .o_data_out(spad_data_out),
        .o_data_out_valid(spad_data_out_valid)
    );

    tile_reader #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SPAD_DATA_WIDTH)
    ) input_tile_reader (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(route_en),
        .i_reg_clear(reg_clear),
        .i_start_addr(i_start_addr),
        .i_addr_end(i_addr_end),
        .i_data_in(spad_data_out),
        .i_data_in_valid(spad_data_out_valid),
        .o_spad_read_en(spad_read_en),
        .o_spad_read_done(o_read_done),
        .o_spad_read_addr(spad_read_addr),
        .o_addr(tr_addr),
        .o_data(tr_data),
        .o_data_valid(tr_data_valid)
    );

    router_controller #(
        .COUNT(ROWS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) input_controller (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_pop_en(i_fifo_pop_en),
        .i_conv_mode(i_conv_mode),
        .i_start_addr(i_start_addr),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size),
        .i_stride(i_stride),
        .i_i_c_size(i_i_c_size),
        .o_id(id),
        .o_start_addr(start_addr),
        .o_end_addr(end_addr),
        .o_addr_write_en(addr_write_en),
        .o_route_en(route_en),
        .o_pop_en(fifo_pop_en),
        .o_reg_clear(reg_clear),
        .i_fifo_pop_ready(fifo_pop_ready),
        .i_fifo_empty(fifo_empty),
        .o_done(o_output_done),
        .o_ready(o_ready),
        .o_context_done(o_context_done)
    );

    assign o_done = fifo_pop_en;

    data_lane_array #(
        .COUNT(ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SPAD_DATA_WIDTH(SPAD_DATA_WIDTH),
        .SPAD_N(SPAD_N),
        .MISO_DEPTH(MISO_DEPTH)
    ) input_router_array (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(reg_clear),
        .i_id(id),
        .i_start_addr(start_addr),
        .i_end_addr(end_addr),
        .i_addr_write_en(addr_write_en),
        .i_ac_en(route_en),
        .i_data(tr_data),
        .i_addr(tr_addr),
        .i_data_valid(tr_data_valid),
        .i_miso_pop_en(fifo_pop_en),
        .i_p_mode(i_p_mode),
        .o_data(o_data),
        .o_data_valid(o_data_valid),
        .o_fifo_full(),
        .o_fifo_empty(fifo_empty),
        .o_route_done(fifo_pop_ready)
    );

endmodule