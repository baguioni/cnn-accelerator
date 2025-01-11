// Acts like a micro instruction dispatcher for input row router
module output_coordinate_generator #(
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear, i_pop_en,
    input logic [ADDR_WIDTH-1:0] i_o_size, i_o_addr, // write address in output buffer
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y, o_o_addr,
);
    logic [ADDR_WIDTH-1:0] reg_o_x, reg_o_y, reg_o_addr;
    logic increment_en, done, row_full, stall;

    // Output feature map counter
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_o_x <= 0;
            reg_o_y <= 0;
            row_counter <= 0;
            done <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_o_x <= 0;
                reg_o_y <= 0;
                row_counter <= 0;
                done <= 0;
            end else if (i_en) begin
                row_counter <= row_counter + 1;
                if (reg_o_y < i_o_size-1) begin
                    reg_o_y <= reg_o_y + 1;
                    done <= 0;
                end else begin
                    reg_o_y <= 0;
                    if (reg_o_x < i_o_size-1) begin
                        reg_o_x <= reg_o_x + 1;
                        done <= 0;
                    end else begin
                        reg_o_x <= 0;
                        done <= 1;
                    end
                end
            end
        end 
    end

    always_comb begin  
        o_o_x = reg_o_x;
        o_o_y = reg_o_y;

    end
endmodule
