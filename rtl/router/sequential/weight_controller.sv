/*
    
    
    
    
    Functions as tile reader 

    - Receive address and offset from controller
    - Read from SRAM
    - Store to MISO FIFO
*/
module weight_controller # (
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_reg_clear, i_write_en,
    input logic [ADDR_WIDTH-1:0] i_addr, i_addr_offset,
    
    // Weight SRAM related signals
    input logic i_data_valid,
    input logic [DATA_LENGTH-1:0][DATA_WIDTH-1:0] i_data,
    output logic o_sram_read_en, 
    output logic [ADDR_WIDTH-1:0] o_read_addr,

    // Output related signals
    input logic i_data_out_en, i_data_out_reset,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic o_empty, o_full, o_data_valid  
);

    logic write_en;
    assign write_en = i_data_valid & !o_full;

    logic [ADDR_WIDTH-1:0] read_counter;

    // Read Controller
    logic sram_read_en = i_write_en & !(i_addr_offset - 1 == read_counter);

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_sram_read_en <= 0;
            read_counter <= 0;
        end else begin
            if (i_reg_clear) begin
                o_sram_read_en <= 0;
                o_read_addr <= 0;
                read_counter <= 0;
            end else if (sram_read_en) begin
                o_sram_read_en <= 1;
                o_read_addr <= i_addr + read_counter;
                read_counter <= read_counter + 1;
            end else begin
                o_sram_read_en <= 0;
                o_read_addr <= 0;
            end
        end
    end



endmodule