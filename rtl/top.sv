/*
    What it should do:
    - Write to weight/input SRAM
    - Control weight and input routers
    - Output input/weight data to the rest of the system
*/

module top (
    input logic i_clk, i_nrst, i_reg_clear,

    // Host-side 
    input logic [SRAM_DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,
    input logic [1:0] i_sram_select, // Select between weight and input SRAM
    input logic i_write_en, i_route_en,
    input logic [1:0] i_p_mode,

    // Input router parameters
    input logic [ADDR_WIDTH-1:0] i_i_start_addr, i_i_addr_end,
    input logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride, 

    // Weight router parameters
    input logic [ADDR_WIDTH-1:0] i_w_start_addr, i_w_addr_offset,
    input logic [ADDR_WIDTH-1:0] i_route_size
);
    localparam int DATA_WIDTH = 8;
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int WEIGHT_SRAM = 0;
    localparam int INPUT_SRAM = 1;
    localparam int ROUTER_COUNT = 4;

    logic sram_w_write_en, sram_i_write_en;

    // Select which SRAM to write to
    always_comb begin
        if (i_sram_select == WEIGHT_SRAM) begin
            sram_w_write_en = i_write_en;
            sram_i_write_en = 0;
        end else if (i_sram_select == INPUT_SRAM) begin
            sram_w_write_en = 0;
            sram_i_write_en = i_write_en;
        end
    end

    logic wr_reroute;

    // Instantiate input router
    input_router #(
        .ROUTER_COUNT(ROUTER_COUNT)
    ) ir_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(ir_en),
        .i_reg_clear(i_reg_clear),
        .i_sram_write_en(sram_i_write_en),
        .i_p_mode(i_p_mode),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_start_addr(i_i_start_addr),
        .i_addr_end(i_i_addr_end),
        .o_read_done(),
        .o_route_done(),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size),
        .i_stride(i_stride),
        .o_data(ir_ifmap),
        .o_data_valid(ir_data_valid),
        .i_data_out_en(ir_data_out_en),
        .o_data_out_ready(ir_route_ready),
        .o_rerouting(wr_reroute)
    );

    // Instantiate weight router
    logic [DATA_WIDTH-1:0] weight;
    logic wr_data_valid;
    logic [ROUTER_COUNT-1:0] ir_data_valid;
    logic [ROUTER_COUNT-1:0][DATA_WIDTH-1:0] ir_ifmap;
    logic [0:ROUTER_COUNT-1][DATA_WIDTH-1:0] s_ifmap;

    weight_router wr_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_fifo_clear(),
        .i_sram_write_en(sram_w_write_en),
        .i_p_mode(i_p_mode),
        .i_route_en(wr_en),
        .i_data_out_en(wr_data_out_en),
        .i_route_reuse(wr_reroute),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_start_addr(i_w_start_addr),
        .i_addr_offset(i_w_addr_offset),
        .i_route_size(i_route_size),
        .o_route_ready(wr_route_ready),
        .o_route_done(),
        .o_data(weight),
        .o_data_valid(wr_data_valid)
    );

    // Controller logic
    logic ir_route_ready, wr_route_ready;
    logic ir_en, wr_en;
    logic ir_data_out_en, wr_data_out_en;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            ir_en <= 0;
            wr_en <= 0;
        end else begin
            if (i_reg_clear) begin
                ir_en <= 0;
                wr_en <= 0;
            end else if(i_route_en) begin
                ir_en <= 1;
                wr_en <= 1;
            end
        end
    end

    // Pop when both routers are ready
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            ir_data_out_en <= 0;
            wr_data_out_en <= 0;
        end else begin
            if (i_reg_clear) begin
                ir_data_out_en <= 0;
                wr_data_out_en <= 0;
            end else if (ir_route_ready & wr_route_ready) begin
                ir_data_out_en <= 1;
                wr_data_out_en <= 1;
            end else begin
                ir_data_out_en <= 0;
                wr_data_out_en <= 0;
            end
        end
    end

    // Systolic Array
    genvar ii;
    generate
        for (ii=0; ii < ROUTER_COUNT; ii++) begin
            assign s_ifmap[ii] = ir_ifmap[ii];
        end
    endgenerate

    systolic_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .S_WIDTH(1),
        .S_HEIGHT(ROUTER_COUNT)
    ) systolic_array_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear || wr_reroute), // Need to add signals to clear only inputs
        .i_pe_en(|ir_data_valid),
        .i_psum_out_en(),
        .i_ifmap(s_ifmap),
        .i_weight(weight),
        .o_ifmap()
    );
endmodule