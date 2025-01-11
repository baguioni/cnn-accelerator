module row_poper #(
    parameter int ROUTER_COUNT = 4
)(
    input i_clk, i_nrst, i_reg_clear,
    input i_en,
    output logic [ROUTER_COUNT-1:0] o_rr_en
);
    logic [ROUTER_COUNT-1:0] counter;

    always_ff @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_rr_en <= 0;
            counter <= 0;
        end else begin
            if (i_reg_clear) begin
                o_rr_en <= 0;
                counter <= 0;
            end else if (i_en) begin
                for (int i = 0; i < ROUTER_COUNT; i = i + 1) begin
                    if (counter >= i) begin
                        o_rr_en[i] <= 1;
                    end else begin
                        o_rr_en[i] <= 0;
                    end 
                end

                if (counter != ROUTER_COUNT) begin
                    counter <= counter + 1;
                end
            end
        end
    end

endmodule