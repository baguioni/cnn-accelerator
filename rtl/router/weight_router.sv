/*
    interface for writing to SRAM
    interface for controling weight router
*/

module weight_router #(
    parameter int SPAD_DATA_WIDTH = 64,
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 8,
    parameter int DATA_LENGTH = 8,

        // MISO FIFO Params
    parameter int DEPTH = 32,
    parameter int FIFO_ADDR = $clog2(DEPTH)
)(
    input logic i_clk, i_nrst, i_reg_clear, i_fifo_clear,
    input logic i_spad_write_en, i_en,
    input logic [1:0] i_p_mode,

    input logic [SPAD_DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,

    // Control parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_addr_offset,
    input logic [ADDR_WIDTH-1:0] i_route_size, // 9 for 3x3 kernel and x depending on number of channels
    
    // Status signals
    output logic o_ready, o_done,

    // Output signals
    input logic i_pop_en, i_reuse_en,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic o_data_valid
);

    // SRAM
    logic spad_data_out_valid;
    logic [SPAD_DATA_WIDTH-1:0] spad_data_out;

    // Controller
    // Read from SRAM and write to MISO FIFO
    logic [ADDR_WIDTH-1:0] read_counter, spad_read_addr; 
    logic spad_read_en, read_en, spad_read_done;
    
    assign spad_read_done = read_counter > i_addr_offset;
    assign read_en = i_en & ~spad_read_done;

    logic [FIFO_ADDR-1:0] fifo_r_pointer;
    logic fifo_pop_en;

    // assign fifo_pop_en = i_pop_en & spad_read_done;
    assign o_ready = spad_read_done & ~spad_data_out_valid;

    spad #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SPAD_DATA_WIDTH)
    ) weight_sram (
        .i_clk(i_clk),
        .i_write_en(i_spad_write_en),
        .i_read_en(spad_read_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_read_addr(spad_read_addr),
        .o_data_out(spad_data_out),
        .o_data_out_valid(spad_data_out_valid)
    );

    // MISO FIFO
    miso_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH)
    ) fifo_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_fifo_clear || i_reg_clear),
        .i_write_en(spad_data_out_valid),
        .i_pop_en(fifo_pop_en),
        .i_p_mode(i_p_mode),
        .i_r_pointer_reset(i_reuse_en),
        .i_data(spad_data_out),
        .i_valid({DATA_LENGTH{spad_data_out_valid}}),
        .o_data(o_data),
        .o_empty(),
        .o_full(),
        .o_pop_valid(o_data_valid)
    );

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            spad_read_en <= 0;
            read_counter <= 0;
            spad_read_addr <= 0;
        end else begin
            if (i_reg_clear) begin
                spad_read_en <= 0;
                spad_read_addr <= 0;
                read_counter <= 0;
            end else if (read_en) begin
                spad_read_en <= 1;
                spad_read_addr <= i_start_addr + read_counter;
                read_counter <= read_counter + 1;
            end else begin
                spad_read_en <= 0;
                spad_read_addr <= 0;
            end
        end
    end

    // Read from MISO FIFO and handle reuse 
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            fifo_r_pointer <= 0;
            o_done <= 0;
            fifo_pop_en <= 0;
        end else begin
            if (i_reg_clear || i_reuse_en) begin
                fifo_r_pointer <= 0;
                fifo_pop_en <= 0;
                o_done <= 0;
            end else if (i_pop_en & spad_read_done) begin
                if (fifo_r_pointer < i_route_size) begin
                    fifo_pop_en <= 1;
                    fifo_r_pointer <= fifo_r_pointer + 1;
                end else begin
                    fifo_pop_en <= 0;
                    o_done <= 1;
                end
            end
        end
    end

endmodule