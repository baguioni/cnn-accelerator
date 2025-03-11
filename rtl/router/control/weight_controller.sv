/*
    Make this generic first, then we can add the DWise Convolution
    Makes more sense to reuse the inputs while going through entire weights
*/
module weight_controller #(
    parameter int COUNT = 4,
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk,
    input logic i_nrst,
    input logic i_en,
    input logic i_reg_clear,

    // Input control signals
    input logic i_pop_en,
    input logic i_conv_mode, // 0: PWise, 1: DWise,

    // Input parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, 
    input logic [ADDR_WIDTH-1:0] i_i_c_size,
    input logic [ADDR_WIDTH-1:0] i_o_c_size,

    // Routing signals
    output logic [COUNT-1:0] o_id,
    output logic [ADDR_WIDTH-1:0] o_start_addr,
    output logic [ADDR_WIDTH-1:0] o_end_addr,
    output logic o_addr_write_en,

    // Control signals
    output logic o_route_en, // enables tile reader and address comparator
    output logic o_pop_en,
    output logic o_reg_clear,
    
    // Status signals
    input logic i_fifo_pop_ready,
    input logic i_fifo_empty,
    output logic o_done,
    output logic o_ready,
    output logic o_context_done
);
    parameter int IDLE = 0;
    parameter int INIT = 1;
    parameter int ADDR_WRITE = 2;
    parameter int C_INCREMENT = 3; 
    parameter int WRITE_STALL = 4;
    parameter int TILE_COMPARISON = 5;
    parameter int DATA_OUT = 6;

    logic [ADDR_WIDTH-1:0] o_c;
    
    logic [2:0] state;
    logic c_increment, c_done;

    assign c_increment = o_x < i_o_c_size - 1;

    logic route_en;
    assign route_en = i_en && !o_done;
    
    logic [ADDR_WIDTH-1:0] prev_addr;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_c <= 0;
            o_id <= 0;
            o_route_en <= 0;
            o_done <= 0;
            state <= IDLE;
            o_pop_en <= 0;
            o_reg_clear <= 0;
            xy_done <= 0;
            o_ready <= 0;
            o_context_done <= 0;
            o_start_addr <= 0;
            o_end_addr <= 0;
            o_addr_write_en <= 0;
            prev_addr <= 0;
        end else if (i_reg_clear) begin
            o_c <= 0;
            o_id <= 0;
            o_route_en <= 0;
            o_done <= 0;
            state <= IDLE;
            o_pop_en <= 0;
            o_reg_clear <= 0;
            xy_done <= 0;
            o_ready <= 0;
            o_context_done <= 0;
            o_start_addr <= 0;
            o_end_addr <= 0;
            o_addr_write_en <= 0;
            prev_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (route_en) begin
                        state <= INIT;
                    end
                end

                INIT: begin
                    o_context_done <= 0;
                    o_reg_clear <= 0;
                    o_ready <= 0;
                    state <= ADDR_WRITE;
                end

                ADDR_WRITE: begin
                    // Modify these signals as needed
                    // NHWC offset calculation
                    o_end_addr <= i_start_addr + o_c * (i_i_c_size);
                    prev_addr <= i_start_addr + o_c * (i_i_c_size);
                    o_start_addr <= prev_addr;
                    o_addr_write_en <= 1;
                    state <= C_INCREMENT;    
                end

                C_INCREMENT: begin
                    if (c_increment) begin
                        o_c <= o_c + 1;
                    end else begin
                        o_c <= 0;
                        c_done <= 1;
                        state <= WRITE_STALL;
                        o_addr_write_en <= 0;
                        // Tell input router done with channels
                    end

                    if (o_id == COUNT - 1) begin
                        o_id <= 0;
                        o_addr_write_en <= 0;
                        state <= WRITE_STALL;
                    end else if (c_increment) begin
                        o_id <= o_id + 1;
                        o_addr_write_en <= 1;
                        state <= ADDR_WRITE;
                    end
                end

                                
                WRITE_STALL: begin
                    state <= TILE_COMPARISON;
                end

                TILE_COMPARISON: begin
                    if (i_fifo_pop_ready) begin
                        o_route_en <= 0;
                        o_ready <= 1;
                        o_pop_en <= 1;
                        state <= DATA_OUT;
                    end else begin
                        o_route_en <= 1;
                    end
                end

                /*
                    Signal to upper level control that data is ready
                */

                DATA_OUT: begin
                    if (i_fifo_empty) begin
                        o_pop_en <= 0;
                        o_reg_clear <= 1;
                        if (c_done) begin
                            o_done <= 1;
                            state <= IDLE;
                        end else begin
                            o_context_done <= 1;
                            // Dont immediately go to IDLE, wait for signal from upper level
                            state <= IDLE;
                        end
                        o_ready <= 0;
                    end else if (i_pop_en) begin
                        o_pop_en <= 1;
                    end
                end
            endcase
        end
    end

endmodule