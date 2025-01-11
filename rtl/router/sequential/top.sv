// Will have to add a control module to handle timing of operations
// Or perhaps higher level operation does this and just waits for done signals
// of each operation so that it can be timed with weight router
module top (
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic i_sram_write_en, i_tile_read_en, i_ag_en, i_ac_en, i_miso_pop_en,

    // SRAM input signals
    input logic [SRAM_DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,

    // Tile Reader Control signals
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_addr_end,
    output logic o_read_done, o_rr_en,

    // Address Generator Control signals
    // Soon remove i_o_x, i_o_y
    // Component should be able to generate its own coordinates
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_size, i_o_size,

    output logic [ROUTER_COUNT-1:0][DATA_WIDTH-1:0] o_data
);
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int ROUTER_COUNT = 4;
    localparam int DATA_WIDTH = 8;

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
        .i_read_en(i_tile_read_en),
        .i_reg_clear(i_reg_clear),
        .i_start_addr(i_start_addr),
        .i_addr_end(i_addr_end),
        .o_buf_read_en(sram_read_en),
        .o_read_done(o_read_done),
        .o_valid_addr(tr_valid_addr),
        .o_read_addr(sram_read_addr),
        .o_data_addr(tr_data_addr)
    );

    logic [ROUTER_COUNT-1:0][ADDR_WIDTH-1:0] o_x, o_y;

    // eventually remove this and replace with a higher level component
    row_router_controller #(
        .ROUTER_COUNT(ROUTER_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) row_router_controller_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_en(i_en),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_o_size(i_o_size),
        .o_x(o_x),
        .o_y(o_y),
        .o_rr_en(o_rr_en)
    );

    router #(
        .ROUTER_COUNT(ROUTER_COUNT),
        .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) router_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_ag_en(i_ag_en),
        .i_ac_en(i_ac_en),
        .i_miso_pop_en(i_miso_pop_en),
        .i_o_x(o_x),
        .i_o_y(o_y),
        .i_i_size(i_i_size),
        .i_start_addr(i_start_addr),
        .i_data(sram_data_out),
        .i_addr(tr_data_addr),
        .i_data_valid(sram_data_out_valid),
        .o_data(o_data)
    );

endmodule