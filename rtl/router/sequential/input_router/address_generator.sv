/*
    Currently, implements 3x3 depthwise convolution address generation with stride = 1.

    TODO:
    - 3x3 depthwise convolution with stride = 2
    - pointwise convolution
    - select between depthwise and pointwise convolution

    NOTES:
    - The stride can actually be handled by the output coordinate generator logic
    thus, no modification is needed in the address generator module.
*/
module address_generator #(
    parameter int ROW_COUNT = 4,
    parameter int ADDR_WIDTH = 6,
    parameter int ADDR_LENGTH = 9,
    parameter int KERNEL_SIZE = 3
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_size, i_start_addr,
    input logic [ROW_COUNT-1:0] i_row_id,
    output logic o_valid, 
    output logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] o_addr,
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y,
    output logic [ROW_COUNT-1:0] o_row_id
);
    logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] addr;
    
    logic write_done;
    
    genvar x, y;
    generate
        for (x = 0; x < KERNEL_SIZE; x = x + 1) begin : gen_x
            for (y = 0; y < KERNEL_SIZE; y = y + 1) begin : gen_y
                localparam int addr_idx = x * KERNEL_SIZE + y;
                always_comb begin
                    addr[addr_idx] = i_start_addr + ((i_o_x + x) * i_i_size + (i_o_y + y));
                end
            end
        end
    endgenerate

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst ) begin
            o_addr <= '0;
            o_o_x <= 0;
            o_o_y <= 0;
            o_valid <= 0;
            o_row_id <= 0;
        end else begin
            if (i_reg_clear) begin
                o_addr <= '0;
                o_o_x <= 0;
                o_o_y <= 0;
                o_valid <= 0;
                o_row_id <= 0;
            end else if (i_en) begin
                o_addr <= addr;
                o_o_x <= i_o_x;
                o_o_y <= i_o_y;
                o_valid <= i_en;
                o_row_id <= i_row_id;
            end else begin
                o_addr <= '0;
                o_o_x <= 0;
                o_o_y <= 0;
                o_valid <= 0;
                o_row_id <= 0;
            end
        end
    end

endmodule
