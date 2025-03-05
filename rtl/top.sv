`include "rtl/global.svh"

module top #(
    // ---- Constants ----
    parameter int DATA_WIDTH = `DATA_WIDTH,

    // ---- Configurable parameters ----
    parameter int SPAD_DATA_WIDTH = `SPAD_DATA_WIDTH,
    parameter int SPAD_N = `SPAD_N,  // This will also be the Peek Width
    parameter int ADDR_WIDTH = `ADDR_WIDTH,  // This will determine depth
    parameter int ROWS = `ROWS,
    parameter int COLUMNS = `COLUMNS,
    parameter int MISO_DEPTH = `MISO_DEPTH,
    parameter int MPP_DEPTH = `MPP_DEPTH
)(
    input logic i_clk, i_nrst, i_reg_clear,

    // Host-side 
    input logic [SPAD_DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,
    input logic i_spad_select, // Select between weight and input SRAM
    input logic i_write_en, i_route_en,
    input logic [1:0] i_p_mode,

    // Input router parameters
    input logic [ADDR_WIDTH-1:0] i_i_start_addr, i_i_addr_end,
    input logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride, 

    // Weight router parameters
    input logic [ADDR_WIDTH-1:0] i_w_start_addr, i_w_addr_offset,
    input logic [ADDR_WIDTH-1:0] i_route_size,

    // Output
    output logic [DATA_WIDTH*2-1:0] o_ofmap,
    output logic o_ofmap_valid,
    output logic o_done
);
    logic spad_w_write_en, spad_i_write_en;

    // Select which SRAM to write to
    always_comb begin
        if (~i_spad_select) begin
            // Weight SRAM
            spad_w_write_en = i_write_en;
            spad_i_write_en = 1'b0;
        end else begin
            // Input SRAM
            spad_w_write_en = 1'b0;
            spad_i_write_en = i_write_en;
        end

    end

    logic wr_reuse_en;

    // Instantiate weight router
    logic [DATA_WIDTH-1:0] weight;
    logic wr_data_valid;
    logic [ROWS-1:0] ir_data_valid;
    logic [ROWS-1:0][DATA_WIDTH-1:0] ir_ifmap;
    logic [0:ROWS-1][DATA_WIDTH-1:0] s_ifmap;

    // Top controller signals
    logic ir_pop_en, wr_pop_en;
    logic ir_ready, wr_ready;
    logic psum_out_en, or_en;
    logic ir_done, wr_done, or_done;

    logic ir_en, wr_en;

    // Systolic Array
    genvar ii;
    generate
        for (ii=0; ii < ROWS; ii++) begin
            assign s_ifmap[ii] = ir_ifmap[ii];
        end
    endgenerate

    logic [0:ROWS-1][DATA_WIDTH*2-1:0] ofmap;

    logic output_done;

    // Instantiate input router
    input_router #(
        .DATA_WIDTH(DATA_WIDTH),
        .SPAD_DATA_WIDTH(SPAD_DATA_WIDTH),
        .SPAD_N(SPAD_N),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ROWS(ROWS),
        .MPP_DEPTH(MPP_DEPTH),
        .MISO_DEPTH(MISO_DEPTH)
    ) ir_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(ir_en),
        .i_reg_clear(i_reg_clear),
        .i_spad_write_en(spad_i_write_en),
        .i_p_mode(i_p_mode),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_start_addr(i_i_start_addr),
        .i_addr_end(i_i_addr_end),
        .o_read_done(),
        .o_done(ir_done),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size),
        .i_stride(i_stride),
        .o_data(ir_ifmap),
        .o_data_valid(ir_data_valid),
        .i_pop_en(ir_pop_en),
        .o_ready(ir_ready),
        .o_context_done(wr_reuse_en),
        .o_output_done(output_done)
    );

    weight_router #(
        .DATA_WIDTH(DATA_WIDTH),
        .SPAD_DATA_WIDTH(SPAD_DATA_WIDTH),
        .SPAD_N(SPAD_N),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MISO_DEPTH(MISO_DEPTH)
    ) wr_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_fifo_clear(),
        .i_spad_write_en(spad_w_write_en),
        .i_p_mode(i_p_mode),
        .i_en(wr_en),
        .i_pop_en(wr_pop_en),
        .i_reuse_en(wr_reuse_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_start_addr(i_w_start_addr),
        .i_addr_offset(i_w_addr_offset),
        .i_route_size(i_route_size),
        .o_ready(wr_ready),
        .o_done(wr_done),
        .o_data(weight),
        .o_data_valid(wr_data_valid)
    );

    top_controller #(
        .ROWS(ROWS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) top_controller_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_route_en(i_route_en),
        .o_ir_en(ir_en),
        .o_wr_en(wr_en),
        .i_ir_ready(ir_ready),
        .i_wr_ready(wr_ready),
        .o_ir_pop_en(ir_pop_en),
        .o_wr_pop_en(wr_pop_en),
        .i_ir_done(ir_done),
        .i_wr_done(wr_done),
        .i_or_done(or_done),
        .i_route_size(i_route_size),
        .o_psum_out_en(psum_out_en),
        .o_or_en(or_en),
        .i_output_done(output_done),
        .o_done(o_done)
    );

    systolic_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .WIDTH(COLUMNS),
        .HEIGHT(ROWS)
    ) systolic_array_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_mode(i_p_mode),
        .i_reg_clear(i_reg_clear || or_done), // Need to add signals to clear only inputs
        .i_pe_en(|ir_data_valid),
        .i_psum_out_en(psum_out_en),
        .i_ifmap(s_ifmap),
        .i_weight(weight),
        .o_ofmap(ofmap)
    );

    output_router #(
        .SPAD_ADDR_WIDTH(ADDR_WIDTH),
        .SPAD_DATA_WIDTH(16),
        .ROWS(ROWS),
        .DATA_WIDTH(DATA_WIDTH)
    ) or_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(or_en),
        .i_ifmap(ofmap),
        .i_valid({ROWS{1'b1}}),
        .o_data_out(o_ofmap),
        .o_valid(o_ofmap_valid),
        .o_done(or_done)
    );
endmodule