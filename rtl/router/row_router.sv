module row_router #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 6,
    parameter int FIFO_DEPTH = 16,
    parameter int HEIGHT = 4 // Number of rows for zero padding
) (
    input logic i_clk, i_nrst, 
    input logic [$clog2(HEIGHT):0] i_row_id,
    input logic i_en, i_reg_clear, i_stall_en, // Control signals

    // ====== Address generator signals ====== 
    input logic [ADDR_WIDTH-1:0] i_k_size, i_k_num, i_i_size, // Input parameters
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, // Output parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, // Start address of tile in input buffer
    output logic o_ag_done,
    
    // ====== Tile Reader signals ====== 
    input logic i_valid_addr,
    input logic [DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_addr,

    // ====== Systolic Array signals ======
    input logic i_pop_en, // Output from data FIFO
    input logic i_zero_padding_en, // Enable zero padding
    input logic [$clog2(HEIGHT):0] i_pad_count, // Number of zeros to add (up to HEIGHT)
    output logic [DATA_WIDTH-1:0] o_data_out
);
    logic [ADDR_WIDTH-1:0] ag_addr, fifo_addr_peek;

    // Address generator Signals
    logic ag_active, addr_hit, en;

    // Address FIFO Signals
    logic fifo_addr_full;
    logic fifo_addr_write_en;
    logic fifo_addr_pop_en;

    // Data FIFO Signals
    logic [DATA_WIDTH-1:0] fifo_data_input;
    logic fifo_data_full;
    logic fifo_data_write_en;
    logic adding_zeros;

    assign fifo_addr_write_en = ag_active && ~fifo_addr_full;
    assign addr_hit = (i_addr == fifo_addr_peek) && i_valid_addr;
    assign en = i_en && ~i_stall_en;
    assign adding_zeros = i_zero_padding_en && (i_pad_count < i_row_id);

    always_comb begin
        if (en) begin
            if (adding_zeros) begin
                fifo_data_write_en = 1;
                fifo_addr_pop_en = 0; // Do not pop address during zero padding
                fifo_data_input = 0;  // Write zero
            end else if (addr_hit) begin
                fifo_data_write_en = 1;
                fifo_addr_pop_en = 1;
                fifo_data_input = i_data_in;
            end else begin
                fifo_data_write_en = 0;
                fifo_addr_pop_en = 0;
                fifo_data_input = 0;
            end
        end else begin
            fifo_data_write_en = 0;
            fifo_addr_pop_en = 0;
            fifo_data_input = 0;
        end
    end

    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ag (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_k_size(i_k_size),
        .i_k_num(i_k_num),
        .i_i_size(i_i_size),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_start_addr(i_start_addr),
        .o_done(o_ag_done),
        .o_active(ag_active),
        .o_addr(ag_addr)
    );

    fifo #(
        .DATA_WIDTH(ADDR_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_addr (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(fifo_addr_write_en),
        .i_pop_en(fifo_addr_pop_en),
        .i_data_in(ag_addr),
        .o_peek_data(fifo_addr_peek),
        .o_pop_out(),
        .o_empty(),
        .o_full(fifo_addr_full)
    );

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_data (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(fifo_data_write_en),
        .i_pop_en(i_pop_en),
        .i_data_in(fifo_data_input),
        .o_pop_out(o_data_out),
        .o_empty(),
        .o_full(fifo_data_full)
    );

endmodule
