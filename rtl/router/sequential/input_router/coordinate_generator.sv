/*
    O = (I-K)/S + 1
*/
module coordinate_generator #(
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear,

    // Parameters
    input logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride, i_start_addr,

    // Output coordinates
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y,

    output logic o_done, o_valid
);
    logic increment_en, first_cycle;

    assign increment_en = i_en && !o_done;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_o_x <= 0;
            o_o_y <= 0;
            o_done <= 0;
            o_valid <= 0;
            first_cycle <= 1;
        end else begin
            if (i_reg_clear) begin
                o_o_x <= 0;
                o_o_y <= 0;
                o_done <= 0;
                o_valid <= 0;
                first_cycle <= 1;
            end else if (increment_en) begin
                if (first_cycle) begin
                    o_o_x <= 0;
                    o_o_y <= 0;
                    o_valid <= 1;
                    first_cycle <= 0;
                end else begin
                    if (o_o_y < (i_o_size * i_stride) - i_stride) begin
                        o_o_y <= o_o_y + i_stride;
                    end else begin
                        o_o_y <= 0;
                        if (o_o_x < (i_o_size * i_stride) - i_stride) begin
                            o_o_x <= o_o_x + i_stride;
                        end else begin
                            o_o_x <= 0;
                            o_done <= 1;
                            o_valid <= 0;
                        end
                    end
                end
            end
        end
    end

endmodule
