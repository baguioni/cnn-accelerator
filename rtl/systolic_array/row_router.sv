module row_router #(
    parameter int DATA_WIDTH = 8,
    parameter int BUF_DEPTH = 64,
    parameter int FIFO_DEPTH = 16
) (
    input logic i_clk, i_nrst, 
    input logic i_en, i_reg_clear, i_stall_en, // Control signals

    // ====== Address generator signals ====== 
    input logic [ADDR_WIDTH-1:0] i_k_size, i_k_num, i_i_size, // Input parameters
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, // Output parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, // Start address of tile in input buffer
    output logic o_ag_done,
    
    // ====== Data selector signals ======
    input logic [DATA_WIDTH-1:0] i_data_in,
    input logic i_fifo_addr_peek_en,
    input logic i_data_hit,
    output logic o_valid_addr,
    output logic [ADDR_WIDTH-1:0] o_read_addr
    // output o_fifo_data_full, // Assume this wont happen
);
    localparam ADDR_WIDTH = $clog2(BUF_DEPTH);
    logic [ADDR_WIDTH-1:0] ag_read_addr;

    // Address generator Signals
    logic ag_active;

    // Address FIFO Signals
    logic fifo_addr_full;
    logic fifo_addr_write_en;
    logic fifo_addr_valid;

    // Data FIFO Signals
    logic fifo_data_full;
    logic fifo_data_write_en;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            fifo_data_write_en <= 1'b0;
        end else begin
            fifo_data_write_en <= i_data_hit && ~fifo_data_full;
        end
    end

    assign fifo_addr_write_en = ag_active && ~fifo_addr_full;

    address_generator #(
        .BUF_DEPTH(BUF_DEPTH)
    ) ag (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_stall_en(i_stall_en),
        .i_k_size(i_k_size),
        .i_k_num(i_k_num),
        .i_i_size(i_i_size),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_start_addr(i_start_addr),
        .o_done(o_ag_done),
        .o_active(ag_active),
        .o_read_addr(ag_read_addr)
    );

    fifo #(
        .DATA_WIDTH(ADDR_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_addr (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(fifo_addr_write_en),
        .i_pop_en(i_data_hit),
        .i_peek_en(i_fifo_addr_peek_en),
        .i_data_in(ag_read_addr),
        .o_pop_out(),
        .o_peek_data(o_read_addr),
        .o_empty(),
        .o_full(fifo_addr_full),
        .o_peek_valid(o_valid_addr)
    );

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_data (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(fifo_data_write_en),
        .i_data_in(i_data_in),
        .o_pop_out(),
        .o_peek_data(),
        .o_empty(),
        .o_full(fifo_data_full)
    );

endmodule