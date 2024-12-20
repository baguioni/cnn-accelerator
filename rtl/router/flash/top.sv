module top (
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic [5:0] i_start_addr, i_o_size,
);
    // Buffer variables
    parameter int BUF_DEPTH = 64,
    parameter int DATA_WIDTH = 8,
    parameter int WRITE_WIDTH = 16,
    parameter int READ_WIDTH = 9,
    parameter int ADDR_WIDTH = $clog2(BUF_DEPTH * WRITE_WIDTH),

    // Router variables
    parameter int SA_HEIGHT = 4,
    parameter int KERNEL_SIZE = 3,
    parameter int DATA_LENGTH = 9,
    parameter int FIFO_DEPTH = 32;

    sram #(
        .DEPTH(BUF_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .WRITE_WIDTH(WRITE_WIDTH),
        .READ_WIDTH(READ_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) sram (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_write_en(),
        .i_read_en(),
        .i_data_in(),
        .i_write_addr(),
        .i_read_addr(),
        .o_data_out()
    );

    router #(
        .SA_HEIGHT(SA_HEIGHT),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) router (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_start_addr(i_start_addr),
        .i_o_size(i_o_size),
        .o_buf_addr(),
        .o_buf_read_en(),
        .i_buf_data(),
        .o_sa_addr()
    );
endmodule