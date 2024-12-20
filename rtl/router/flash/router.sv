module router #(
    parameter int SA_HEIGHT = 4,
    parameter int KERNEL_SIZE = 3,
    parameter int ADDR_WIDTH = 6
    parameter int DATA_WIDTH = 8,
    parameter int DATA_LENGTH = 9,
    parameter int FIFO_DEPTH = 32
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear, 

    // Feature map related signals
    input [ADDR_WIDTH-1:0] i_start_addr, i_o_size, i_i_size,

    // Buffer related signals
    output logic [0:DATA_LENGTH-1][ADDR_WIDTH-1:0] o_buf_addr,
    output logic o_buf_read_en,
    input logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] i_buf_data,
    
    // Systolic array related signals
    output logic [0:SA_HEIGHT-1][DATA_WIDTH-1:0] o_sa_addr,
);
    localparam SA_BITS = $clog2(SA_HEIGHT);
    logic [SA_BITS-1:0] row_number;
    logic [ADDR_WIDTH-1:0] o_x, o_y;
    logic miso_fifo_write_en, ag_en;

    router_controller #(
        .SA_HEIGHT(SA_HEIGHT),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) router_controller (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_compute_done(),
        .i_start_addr(i_start_addr),
        .i_o_size(i_o_size),
        .o_row_number(row_number),
        .o_o_x(o_x),
        .o_o_y(o_y),
        .o_done(),
        .o_ag_en(ag_en)
    );

    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) address_generator (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(ag_en),
        .i_reg_clear(i_reg_clear),
        .i_o_x(o_x),
        .i_o_y(o_y),
        .i_i_size(i_i_size),
        .i_start_addr(i_start_addr),
        .o_valid(miso_fifo_write_en),
        .o_addr(o_buf_addr)
    );

    logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] i_data [SA_HEIGHT-1:0];

    genvar i;
    generate 
        for (i=0; i<SA_HEIGHT; i=i+1) begin : gen_miso_fifo
            miso_fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .FIFO_DEPTH(FIFO_DEPTH),
                .DATA_LENGTH(DATA_LENGTH),
                .INDEX(i)
            ) miso_fifo (
                .i_clk(i_clk),
                .i_nrst(i_nrst),
                .i_clear(i_reg_clear),
                .i_write_en(miso_fifo_write_en),
                .i_pop_en(),
                .i_data(i_data[i]),
                .i_valid(),
                .i_current_row(row_number),
                .o_data(),
                .o_empty(),
                .o_full()
            );

        end
    endgenerate
endmodule