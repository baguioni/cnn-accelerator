/*
    Get addr from row_router addr fifo
    Compare with current addr
    If match, send data to row_router data fifo and set data_hit to 1
    If no match, send 0 to row_router data fifo and set data_hit to 0
*/

module data_selector #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 6,
    parameter int HEIGHT = 4
) (
    input logic i_clk, i_nrst, 
    input logic i_en, i_reg_clear, i_stall_en, // Control signals

    // ====== Tile reader signals ======
    input logic i_valid_addr,
    input logic [DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_current_addr,

    // ====== Row router signals ======
    input logic [0:HEIGHT-1] i_rr_valid_addr,
    input [0:HEIGHT-1][ADDR_WIDTH-1:0] i_rr_addr,
    output logic [0:HEIGHT-1][DATA_WIDTH-1:0] o_rr_data,
    output logic [0:HEIGHT-1] o_rr_data_hit, 
    output logic o_rr_fifo_addr_peek_en
);

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_rr_fifo_addr_peek_en <= 1'b0;
            for (int i = 0; i < HEIGHT; i++) begin
                o_rr_data[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (i_en && ~i_stall_en && i_valid_addr) begin
            o_rr_fifo_addr_peek_en <= 1'b1;
            for (int i = 0; i < HEIGHT; i++) begin
                if (i_current_addr == i_rr_addr[i] ) begin
                    o_rr_data[i] <= i_data_in;
                end else begin
                    o_rr_data[i] <= {DATA_WIDTH{1'b0}};
                end
            end
        end else begin
            o_rr_fifo_addr_peek_en <= 1'b0;
        end
    end

    always_comb begin
        if (i_en && ~i_stall_en & i_valid_addr) begin
            for (int i = 0; i < HEIGHT; i++) begin
                if (i_current_addr == i_rr_addr[i] ) begin
                    o_rr_data_hit[i] = 1'b1 & i_rr_valid_addr[i];
                end else begin
                    o_rr_data_hit[i] = 1'b0;
                end
            end
        end else begin
            for (int i = 0; i < HEIGHT; i++) begin
                o_rr_data_hit[i] = 1'b0;
            end
        end
    end

endmodule