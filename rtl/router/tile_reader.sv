module tile_reader #(
    parameter int DATA_WIDTH = 8,
    parameter int BUF_DEPTH = 64,
    parameter int FIFO_DEPTH = 16
) (
    input logic i_clk, i_nrst, 
    input logic i_read_en, i_reg_clear, // Control signals
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_addr_offset,  
    input logic [DATA_WIDTH-1:0] i_data_in,
    output logic o_buf_read_en, o_read_done, o_valid_addr,
    output logic [ADDR_WIDTH-1:0] o_buf_read_addr, o_buf_prev_read_addr,
    output logic [DATA_WIDTH-1:0] o_data_out
);
    localparam ADDR_WIDTH = $clog2(BUF_DEPTH);

    logic [ADDR_WIDTH-1:0] reg_counter, reg_buf_read_addr, reg_buf_prev_read_addr;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_counter <= 0;
            reg_buf_read_addr <= 0;
            o_read_done <= 0;
            o_buf_read_en <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_counter <= 0;
                reg_buf_read_addr <= 0;
                o_read_done <= 0;
                o_buf_read_en <= 0;
            end else if (i_read_en & ~o_read_done) begin
                if (reg_counter <= i_addr_offset) begin
                    o_buf_read_en <= 1;
                    reg_buf_read_addr <= i_start_addr + reg_counter;
                    reg_counter <= reg_counter + 1;
                end else begin
                    o_buf_read_en <= 0;
                    reg_counter <= 0;
                    reg_buf_read_addr <= 0;
                    o_read_done <= 1;
                end
            end
        end
    end

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_buf_prev_read_addr <= 0;
            o_valid_addr <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_buf_prev_read_addr <= 0;
                o_valid_addr <= 0;
            end else if (i_read_en & ~o_read_done) begin
                if (reg_counter <= i_addr_offset + 1) begin
                    reg_buf_prev_read_addr <= reg_buf_read_addr;
                    o_valid_addr <= 1;
                end
            end
        end
    end

    always_comb begin
        o_data_out = i_data_in;
        o_buf_read_addr = reg_buf_read_addr;
        o_buf_prev_read_addr = reg_buf_prev_read_addr;
    end


    fifo #(
        .DATA_WIDTH(ADDR_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_addr (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(i_read_en),
        .i_pop_en(),
        .i_peek_en(),
        .i_data_in(reg_buf_prev_read_addr),
        .o_pop_out(),
        .o_peek_data(),
        .o_empty(),
        .o_full()
    );

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_data (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(i_read_en),
        .i_pop_en(),
        .i_peek_en(),
        .i_data_in(i_data_in),
        .o_pop_out(),
        .o_peek_data(),
        .o_empty(),
        .o_full()
    );
endmodule