/*
    - When both IR and WR are ready, send pop_en signal to both
    - When route is enabled, send en signal to both
    - When IR (context_done or done) and WR (done) are ready:
        - Estimate when calculation is done
        - Send psum_out signal
        - Send en signal to output router
*/


module top_controller # (
    parameter int ROUTER_COUNT = 2,
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_reg_clear,


    input logic i_route_en,
    output logic o_ir_en, o_wr_en,

    // Ready signals
    input logic i_ir_ready, i_wr_ready,
    output logic o_ir_pop_en, o_wr_pop_en,


    // Done signals
    input logic i_ir_done, i_wr_done, i_or_done,

    // Output router signals
    input logic [ADDR_WIDTH-1:0] i_route_size,
    output logic o_psum_out_en,
    output logic o_or_en
);

    // Route signals
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_ir_en <= 0;
            o_wr_en <= 0;
        end else begin
            if (i_reg_clear) begin
                o_ir_en <= 0;
                o_wr_en <= 0;
            end else if(i_route_en) begin
                o_ir_en <= 1;
                o_wr_en <= 1;
            end
        end
    end

    // Pop at the same time when both routers are ready
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_ir_pop_en <= 0;
            o_wr_pop_en <= 0;
        end else begin
            if (i_reg_clear) begin
                o_ir_pop_en <= 0;
                o_wr_pop_en <= 0;
            end else if (i_ir_ready & i_wr_ready) begin
                o_ir_pop_en <= 1;
                o_wr_pop_en <= 1;
            end else begin
                o_ir_pop_en <= 0;
                o_wr_pop_en <= 0;
            end
        end
    end


    // Output router 

    enum logic [1:0] {
        IDLE,
        COMPUTATION,
        OUT,
        DONE
    } state;

    logic or_start;

    assign or_start = i_ir_done & i_wr_done & (~i_or_done);

    logic [ADDR_WIDTH-1:0] comp_cntr;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_psum_out_en <= 0;
            o_or_en <= 0;
            comp_cntr <= 0;

            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (or_start) begin
                        o_psum_out_en <= 0;
                        o_or_en <= 0;
                        comp_cntr <= 0;
                        state <= COMPUTATION;
                    end else begin
                        state <= IDLE;
                    end
                end

                COMPUTATION: begin
                    if (comp_cntr < ROUTER_COUNT-1) begin
                        comp_cntr <= comp_cntr + 1;
                        state <= COMPUTATION;
                    end else begin
                        o_psum_out_en <= 1;
                        comp_cntr <= 0;
                        state <= OUT;
                    end
                end

                OUT: begin
                    o_psum_out_en <= 0;
                    if (i_or_done) begin
                        o_or_en <= 0;
                        state <= DONE;
                    end else begin
                        o_or_en <= 1;
                        state <= OUT;
                    end
                end

                DONE: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end






    // always_ff @(posedge i_clk or negedge i_nrst) begin
    //     if (~i_nrst) begin
    //         comp_cntr <= 0;
    //         or_start <= 0;
    //     end else begin
    //         if (i_reg_clear) begin
    //             comp_cntr <= 0;
    //             or_start <= 0;
    //         end else if (comp_status) begin
    //             if (comp_cntr < i_route_size + ROUTER_COUNT - 1) begin
    //                 comp_cntr <= comp_cntr + 1;
    //             end else begin
    //                 comp_cntr <= 0;
    //                 or_start <= 1;
    //             end
    //         end
    //     end
    // end

    // logic or_en;
    // assign or_en = or_start & ~i_or_done;

    // always_ff @(posedge i_clk or negedge i_nrst) begin
    //     if (~i_nrst) begin
    //         o_psum_out_en <= 0;
    //     end else begin
    //         if (i_reg_clear) begin
    //             o_psum_out_en <= 0;
    //         end else if (or_en) begin
    //             o_psum_out_en <= 1;
    //             if (o_psum_out_en) begin
    //                 o_or_en <= 1;
    //             end
    //         end else begin
    //             o_psum_out_en <= 0;
    //             o_or_en <= 0;
    //         end
    //     end
    // end
endmodule