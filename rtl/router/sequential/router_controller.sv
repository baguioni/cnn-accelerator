/*
    Receives starting address and output size
    Outputs the output feature map coordinates
    Stalls when row routers are busy 
*/

module router_controller #(
    parameter int ROW_COUNT = 4,
    parameter int ADDR_WIDTH = 8
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear,

    // Input parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_o_size,

    // Output coordinates
    output logic [ROW_COUNT-1:0] o_row_id,
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y,

    // Control signals
    output logic o_ag_en, o_ac_en, o_tile_read_en, o_pop_en,

    // Status signals
    input logic i_addr_empty, i_data_empty,
    output logic o_done, o_reg_clear
);
    parameter int IDLE = 0;
    parameter int INIT = 1;
    parameter int OUTPUT_COORDINATE_GEN = 2;
    parameter int TILE_COMPARISON = 3;
    parameter int DATA_OUT = 4;

    logic [2:0] state;


    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst || i_reg_clear) begin
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
        end else begin
            case (state)
                IDLE: begin
                    if (i_en && !o_done) begin
                        state <= INIT;
                        // Start with (0, 0)
                    end
                end
                INIT: begin
                    o_ag_en <= 1;
                    o_reg_clear <= 0;
                    state <= OUTPUT_COORDINATE_GEN;
                end
                OUTPUT_COORDINATE_GEN: begin
                    // Output feature map row counter
                    if (o_o_y < i_o_size - 1) begin
                        o_o_y <= o_o_y + 1;
                    end else begin
                        o_o_y <= 0;
                        if (o_o_x < i_o_size - 1) begin
                            o_o_x <= o_o_x + 1;
                            // Stall when row routers are busy
                            // Proceed to tile comparison
                        end else begin
                            o_o_x <= 0;
                            o_done <= 1; // Proceed to tile comparison
                            state <= TILE_COMPARISON;
                            o_ag_en <= 0;
                        end
                    end

                    if (o_row_id == ROW_COUNT - 1) begin
                        o_row_id <= 0;
                        o_ag_en <= 0;
                        state <= TILE_COMPARISON;
                    end else begin
                        o_row_id <= o_row_id + 1;
                        o_ag_en <= 1;
                        // Output feature map counter
                    end
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
                    end else begin
                        o_tile_read_en <= 1;
                        o_ac_en <= 1;
                    end
                end
                DATA_OUT: begin
                    if (i_data_empty) begin
                        o_pop_en <= 0;
                        o_reg_clear <= 1;
                        if (o_done) begin
                            state <= IDLE;
                        end else begin
                            state <= INIT;
                        end
                    end else begin
                        o_pop_en <= 1;
                    end
                end
            endcase
        end
    end



endmodule