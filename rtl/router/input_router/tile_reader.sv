/*
    Basically, this module is a simple counter 
    that generates addresses for the buffer to read from.
*/
module tile_reader #(
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, 

     // Control signals
    input logic i_read_en, i_reg_clear,
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_addr_end,  
    
    // Buffer signals
    // input logic [DATA_WIDTH-1:0] i_data_in,
    output logic o_buf_read_en, o_read_done, o_valid_addr,
    output logic [ADDR_WIDTH-1:0] o_read_addr, 
    
    // Routing signals
    output logic [ADDR_WIDTH-1:0] o_data_addr
    // output logic [DATA_WIDTH-1:0] o_data
);
    logic [ADDR_WIDTH-1:0] reg_counter, reg_read_addr, reg_prev_read_addr;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_counter <= 0;
            reg_read_addr <= 0;
            o_read_done <= 0;
            o_buf_read_en <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_counter <= 0;
                reg_read_addr <= 0;
                o_read_done <= 0;
                o_buf_read_en <= 0;
            end else if (i_read_en & ~o_read_done) begin
                if (reg_counter <= i_addr_end) begin
                    o_buf_read_en <= 1;
                    reg_read_addr <= i_start_addr + reg_counter;
                    reg_counter <= reg_counter + 1;
                end else begin
                    o_buf_read_en <= 0;
                    reg_counter <= 0;
                    reg_read_addr <= 0;
                    o_read_done <= 1;
                end
            end
        end
    end

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_prev_read_addr <= 0;
            o_valid_addr <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_prev_read_addr <= 0;
                o_valid_addr <= 0;
            end else if (i_read_en & ~o_read_done) begin
                if (reg_counter <= i_addr_end + 1) begin
                    reg_prev_read_addr <= reg_read_addr;
                    o_valid_addr <= 1;
                end
            end
        end
    end

    always_comb begin
        // o_data = i_data_in;
        o_read_addr = reg_read_addr;
        o_data_addr = reg_prev_read_addr;
    end
endmodule