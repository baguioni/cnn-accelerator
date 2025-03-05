/*
    Receives starting address and output size
    Outputs the output feature map coordinates
    Stalls when row routers are busy 
    Should signal that is working on other coordinates
*/

module ir_controller #(
    parameter int ROW_COUNT = 4,
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear,

    // Input control signals
    input logic i_pop_en,

    // Input parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_o_size, i_stride,

    // Output coordinates
    output logic [ROW_COUNT-1:0] o_row_id,
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y,

    // Control signals
    output logic o_ag_en, o_ac_en, o_tile_read_en, o_pop_en,

    // Status signals
    input logic i_addr_empty, i_data_empty,
    output logic o_done, o_reg_clear, o_ready, o_context_done,
    output [2:0] o_state
);
    parameter int IDLE = 0;
    parameter int INIT = 1;
    parameter int OUTPUT_COORDINATE_GEN = 2;
    parameter int WRITE_STALL = 3;
    parameter int TILE_COMPARISON = 4;
    parameter int DATA_OUT = 5;
    

    logic [2:0] state;
    logic y_increment, x_increment, xy_increment;
    logic done_coordinate_gen, en;

    assign en = i_en && !o_done;

    assign y_increment = o_o_y < (i_o_size * i_stride) - i_stride;
    assign x_increment = o_o_x < (i_o_size * i_stride) - i_stride;
    assign xy_increment = y_increment || x_increment;

    assign o_state = state;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_o_x <= 0;
            o_o_y <= 0;
            o_row_id <= 0;
            o_done <= 0;
            state <= IDLE;
            o_ag_en <= 0;
            o_ac_en <= 0;
            o_tile_read_en <= 0;
            o_pop_en <= 0;
            o_reg_clear <= 0;
            done_coordinate_gen <= 0;
            o_ready <= 0;
            o_context_done <= 0;
        end else if (i_reg_clear) begin
            o_o_x <= 0;
            o_o_y <= 0;
            o_row_id <= 0;
            o_done <= 0;
            state <= IDLE;
            o_ag_en <= 0;
            o_ac_en <= 0;
            o_tile_read_en <= 0;
            o_pop_en <= 0;
            o_reg_clear <= 0;
            done_coordinate_gen <= 0;
            o_ready <= 0;
            o_context_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (en) begin
                        state <= INIT;
                        // Start with (0, 0)
                    end
                end
                INIT: begin
                    o_context_done <= 0;
                    o_ag_en <= 1;
                    o_reg_clear <= 0;
                    o_ready <= 0;
                    state <= OUTPUT_COORDINATE_GEN;
                end
                OUTPUT_COORDINATE_GEN: begin
                    // Output feature map row counter
                    if (y_increment) begin
                        o_o_y <= o_o_y + i_stride;
                    end else begin
                        o_o_y <= 0;
                        if (x_increment) begin
                            o_o_x <= o_o_x + i_stride;
                            // Stall when row routers are busy
                            // Proceed to tile comparison
                        end else begin
                            o_o_x <= 0;
                            done_coordinate_gen <= 1; // Proceed to tile comparison
                            state <= WRITE_STALL;
                            o_ag_en <= 0;
                        end
                    end

                    if (o_row_id == ROW_COUNT - 1) begin
                        o_row_id <= 0;
                        o_ag_en <= 0;
                        state <= WRITE_STALL;
                    end else if (xy_increment) begin
                        o_row_id <= o_row_id + 1;
                        o_ag_en <= 1;
                    end
                end
                WRITE_STALL: begin
                    state <= TILE_COMPARISON;
                end

                /*
                    enable tile reader
                    enable address comparator

                    stop when router_addr_empty is high
                */
                TILE_COMPARISON: begin
                    if (i_addr_empty) begin
                        o_tile_read_en <= 0;
                        o_ac_en <= 0;
                        state <= DATA_OUT;
                        o_ready <= 1;
                        o_pop_en <= 1;
                    end else begin
                        o_tile_read_en <= 1;
                        o_ac_en <= 1;
                    end
                end

                /*
                    Signal to upper level control that data is ready
                */

                DATA_OUT: begin
                    if (i_data_empty) begin
                        o_pop_en <= 0;
                        o_reg_clear <= 1;
                        if (done_coordinate_gen) begin
                            o_done <= 1;
                            state <= IDLE;
                        end else begin
                            // Signal to tell weight router to reuse
                            o_context_done <= 1;
                            state <= INIT;
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