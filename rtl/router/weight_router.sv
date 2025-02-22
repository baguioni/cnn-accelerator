/*
    interface for writing to SRAM
    interface for controling weight router
*/

module weight_router (
    input logic i_clk, i_nrst, i_reg_clear, i_fifo_clear,
    input logic i_sram_write_en, i_en,
    input logic [1:0] i_p_mode,

    input logic [SRAM_DATA_WIDTH-1:0] i_data_in,
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
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int DATA_WIDTH = 8;
    localparam int DATA_LENGTH = 8;

    // MISO FIFO Params
    localparam int DEPTH = 32;
    localparam int FIFO_ADDR = $clog2(DEPTH);

    // SRAM
    logic sram_data_out_valid;
    logic [SRAM_DATA_WIDTH-1:0] sram_data_out;
    sram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SRAM_DATA_WIDTH)
    ) weight_sram (
        .i_clk(i_clk),
        .i_write_en(i_sram_write_en),
        .i_read_en(sram_read_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_read_addr(sram_read_addr),
        .o_data_out(sram_data_out),
        .o_data_out_valid(sram_data_out_valid)
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
        .i_write_en(sram_data_out_valid),
        .i_pop_en(fifo_pop_en),
        .i_p_mode(i_p_mode),
        .i_r_pointer_reset(i_reuse_en),
        .i_data(sram_data_out),
        .i_valid({DATA_LENGTH{sram_data_out_valid}}),
        .o_data(o_data),
        .o_empty(),
        .o_full(),
        .o_pop_valid(o_data_valid)
    );

    // Controller
    // Read from SRAM and write to MISO FIFO
    logic [ADDR_WIDTH-1:0] read_counter, sram_read_addr; 
    logic sram_read_en, read_en, sram_read_done;
    assign sram_read_done = read_counter > i_addr_offset;
    assign read_en = i_en & ~sram_read_done;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            sram_read_en <= 0;
            read_counter <= 0;
            sram_read_addr <= 0;
        end else begin
            if (i_reg_clear) begin
                sram_read_en <= 0;
                sram_read_addr <= 0;
                read_counter <= 0;
            end else if (read_en) begin
                sram_read_en <= 1;
                sram_read_addr <= i_start_addr + read_counter;
                read_counter <= read_counter + 1;
            end else begin
                sram_read_en <= 0;
                sram_read_addr <= 0;
            end
        end
    end

    logic [FIFO_ADDR-1:0] fifo_r_pointer;
    logic fifo_pop_en;

    // assign fifo_pop_en = i_pop_en & sram_read_done;
    assign o_ready = sram_read_done & ~sram_data_out_valid;

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
            end else if (i_pop_en & sram_read_done) begin
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