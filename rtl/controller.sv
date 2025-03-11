/*
    - When both IR and WR are ready, send pop_en signal to both
    - When route is enabled, send en signal to both
    - When IR (context_done or done) and WR (done) are ready:
        - Estimate when calculation is done
        - Send psum_out signal
        - Send en signal to output router
*/


module top_controller # (
    parameter int ROWS = 2,
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk,
    input logic i_nrst,
    input logic i_reg_clear,

    // SPAD related signals
    // input logic i_spad_write_en,
    // input logic i_spad_select, // 0 for weight, 1 for input
    // output logic o_spad_w_write_en,
    // output logic o_spad_i_write_en,

    // Enable signals
    input logic i_route_en,
    output logic o_ir_en,
    output logic o_wr_en,
    output logic o_ir_pop_en,
    output logic o_wr_pop_en,

    // Ready signals
    input logic i_ir_ready,
    input logic i_wr_ready,

    // Done signals
    input logic i_ir_context_done,
    input logic i_wr_context_done,
    input logic i_ir_done,
    input logic i_wr_done,
    output logic o_done,

    // FIFO pointer reset signals
    output o_ir_fifo_ptr_reset,
    output o_wr_fifo_ptr_reset,
);
    logic [2:0] state;
    parameter int IDLE = 0;
    parameter int SPAD_WRITE = 1; // More for the AXI. Future work
    parameter int ACTIVATION_ROUTING = 2;
    parameter int COMPUTE = 3;
    parameter int OUTPUT_ROUTING = 4;
    parameter int DONE = 5;

    // Create an FSM to control the entire process
    /*
        IDLE:
        ACTIVATION_ROUTING: when route is enabled, then route
        BOTH_ROUTE: when both weight and input routers are ready then pop
        COMPUTE: when input router finished popping, then stop
        OUTPUT_ROUTING
        DONE
    */


    always_ff @(posedge i_clk or negedge i_nrst) begin
        if(~i_nrst) begin
            o_ir_en <= 0;
            o_wr_en <= 0;
            o_ir_pop_en <= 0;
            o_wr_pop_en <= 0;
            o_done <= 0;
            o_ir_fifo_ptr_reset <= 0;
            o_wr_fifo_ptr_reset <= 0;
            state <= IDLE;
        end else if (i_reg_clear) begin
            o_ir_en <= 0;
            o_wr_en <= 0;
            o_ir_pop_en <= 0;
            o_wr_pop_en <= 0;
            o_done <= 0;
            o_ir_fifo_ptr_reset <= 0;
            o_wr_fifo_ptr_reset <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (i_route_en) begin
                        o_ir_en <= 1;
                        o_wr_en <= 1;
                        state <= ACTIVATION_ROUTING;
                    end else begin
                        state <= IDLE;
                    end
                end

                ACTIVATION_ROUTING: begin
                    // Set to low to prevent router to autoroute after compute
                    o_ir_en <= 0;
                    o_wr_en <= 0;
                    if (i_ir_ready & i_wr_ready) begin
                        o_ir_pop_en <= 1;
                        o_wr_pop_en <= 1;
                        state <= COMPUTE;
                    end else begin
                        state <= ACTIVATION_ROUTING;
                    end
                end
                
                COMPUTE: begin
                    if (i_ir_done & i_wr_done) begin
                        state <= OUTPUT_ROUTING;
                    end else if (i_ir_context_done & i_wr_context_done) begin
                        // Route Weights and reset pointers of Input
                        o_wr_en <= 1;
                        o_ir_fifo_ptr_reset <= 1;
                        state <= ACTIVATION_ROUTING;
                    end else if (i_ir_context_done & i_wr_done) begin
                        // Route Inputs
                        state <= COMPUTE;
                    end
                end
            endcase
        end
    end



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
                    if (comp_cntr < ROWS-1) begin
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

    // Finished computing entire output
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_done <= 0;
        end else begin
            if (i_reg_clear) begin
                o_done <= 0;
            end else if (i_output_done && i_wr_done && i_or_done) begin
                o_done <= 1;
            end else begin
                o_done <= 0;
            end
        end
    end
endmodule