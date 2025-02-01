// Will have to add a control module to handle timing of operations
// Or perhaps higher level operation does this and just waits for done signals
// of each operation so that it can be timed with weight router
module input_router (
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic i_sram_write_en, 

    // SRAM input signals
    input logic [SRAM_DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,

    // Tile Reader Control signals
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_addr_end,
    output logic o_read_done, o_route_done,

    // Address Generator Control signals
    // Soon remove i_o_x, i_o_y
    // Component should be able to generate its own coordinates
    input logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride,

    output logic [ROUTER_COUNT-1:0][DATA_WIDTH-1:0] o_data,

    // Upper level control signals
    input logic i_data_out_en,
    output logic o_data_out_ready, o_rerouting
);
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int ROUTER_COUNT = 4;
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_LENGTH = 9;

    sram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SRAM_DATA_WIDTH)
    ) input_sram (
        .i_clk(i_clk),
        .i_write_en(i_sram_write_en),
        .i_read_en(sram_read_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_read_addr(sram_read_addr),
        .o_data_out(sram_data_out),
        .o_data_out_valid(sram_data_out_valid)
    );

    logic [SRAM_DATA_WIDTH-1:0] sram_data_out;
    logic sram_data_out_valid;
    logic [ADDR_WIDTH-1:0] sram_read_addr, tr_data_addr;
    logic sram_read_en, tr_valid_addr;


    tile_reader #(
        .DATA_WIDTH(SRAM_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) tile_reader_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_read_en(tile_read_en),
        .i_reg_clear(router_reg_clear),
        .i_start_addr(i_start_addr),
        .i_addr_end(i_addr_end),
        .o_buf_read_en(sram_read_en),
        .o_read_done(o_read_done),
        .o_valid_addr(tr_valid_addr),
        .o_read_addr(sram_read_addr),
        .o_data_addr(tr_data_addr)
    );

    logic [ROUTER_COUNT-1:0] row_id, router_row_id;
    logic [ADDR_WIDTH-1:0] o_x, o_y;
    logic ag_en, ac_en, tile_read_en, pop_en, router_reg_clear;

    input_router_controller #(
        .ROW_COUNT(ROUTER_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) controller (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_data_out_en(i_data_out_en),
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
        .o_done(o_route_done),
        .o_reg_clear(router_reg_clear),
        .o_data_out_ready(o_data_out_ready),
        .o_rerouting(o_rerouting)
    );

    logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] ag_addr;
    logic ag_valid;
    address_generator #(
        .ROW_COUNT(ROUTER_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ADDR_LENGTH(ADDR_LENGTH),
        .KERNEL_SIZE(3)
    ) address_gen (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(ag_en),
        .i_reg_clear(router_reg_clear),
        .i_o_x(o_x),
        .i_o_y(o_y),
        .i_i_size(i_i_size),
        .i_start_addr(i_start_addr),
        .o_valid(ag_valid),
        .o_addr(ag_addr),
        .i_row_id(row_id),
        .o_row_id(router_row_id)
    );

    logic router_addr_empty, router_data_empty;

    /*
        When routing data.

            When reading from tile and all the data has been fetched
                o_addr_empty will be high
            When all the data has been pushed from the router
                o_data_empty will be high

    */
    row_group #(
        .ROUTER_COUNT(ROUTER_COUNT),
        .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) row_group (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(router_reg_clear),
        .i_ag_en(ag_en),
        .i_ac_en(ac_en),
        .i_miso_pop_en(pop_en & i_data_out_en), // originally pop_en
        .i_ag_addr(ag_addr),
        .i_ag_valid(ag_valid),
        .i_row_id(router_row_id),
        .i_data(sram_data_out),
        .i_addr(tr_data_addr),
        .i_data_valid(sram_data_out_valid),
        .o_data(o_data),
        .o_data_empty(router_data_empty),
        .o_addr_empty(router_addr_empty)
    );

endmodule