module address_generator #(
    parameter int ROWS = 4,
    parameter int ADDR_WIDTH = 6,
    parameter int ADDR_LENGTH = 9,
    parameter int KERNEL_SIZE = 3
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_c, i_i_size, i_i_c_size, 
    input logic [ADDR_WIDTH-1:0] i_start_addr,
    input logic [ROWS-1:0] i_row_id,
    output logic o_valid, 
    output logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] o_addr,
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y,
    output logic [ROWS-1:0] o_row_id
);
    logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] addr;
    
    logic write_done;
    
    // For DWise Conv
    // generate address for each element corresponding to the sliding window
    genvar x, y;
    generate  
        for (x = 0; x < KERNEL_SIZE; x = x + 1) begin : gen_x
            for (y = 0; y < KERNEL_SIZE; y = y + 1) begin : gen_y
                localparam int addr_idx = x * KERNEL_SIZE + y;
                always_comb begin
                    if (i_en) begin
                    // offset_nchw(n, c, h, w) = c * HW + h * W + w
                    // Uncomment if using NCHW format
                    // addr[addr_idx] = i_start_addr + ((i_o_x + x) * i_i_size + (i_o_y + y));

                    // offset_nhwc(n, c, h, w) = h * WC + w * C + c
                    // Uncomment if using NHWC format
                        addr[addr_idx] = i_start_addr + (i_o_x + x) * i_i_size * i_i_c_size + (i_o_y + y) * i_i_c_size + i_i_c;
                    end else begin
                        addr[addr_idx] = '0;
                    end
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
