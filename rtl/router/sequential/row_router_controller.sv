module row_router_controller #(
    parameter int ROUTER_COUNT = 4,
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_reg_clear,
    input logic i_en,
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_o_size,
    output logic [ROUTER_COUNT-1:0][ADDR_WIDTH-1:0] o_x, o_y,
    output logic o_rr_en
);
    logic [ROUTER_COUNT-1:0][ADDR_WIDTH-1:0] reg_o_x, reg_o_y;
    logic [ROUTER_COUNT-1:0] counter;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if(~i_nrst) begin
            counter <= 0;
            o_rr_en <= 0;
        end else begin
            if(i_reg_clear) begin
                counter <= 0;
                o_rr_en <= 0;
            end else if(i_en) begin
                if (counter == 0) begin
                    reg_o_x[0] <= i_o_x;
                    reg_o_y[0] <= i_o_y;
                    counter <= counter + 1;
                end else begin
                    if (counter < ROUTER_COUNT) begin
                        if (reg_o_y[counter - 1] < i_o_size - 1) begin
                            reg_o_y[counter] <= reg_o_y[counter - 1] + 1;
                            reg_o_x[counter] <= reg_o_x[counter - 1];
                        end else begin
                            reg_o_y[counter] <= 0;
                            if (reg_o_x[counter - 1] < i_o_size - 1) begin
                                reg_o_x[counter] <= reg_o_x[counter - 1] + 1;
                            end else begin
                                reg_o_x[counter] <= 0;
                            end
                        end

                        counter <= counter + 1;
                    end else begin
                        o_rr_en <= 1;
                    end
                end
            end
        end
    end

    always_comb begin
        o_x = reg_o_x;
        o_y = reg_o_y;
    end
endmodule