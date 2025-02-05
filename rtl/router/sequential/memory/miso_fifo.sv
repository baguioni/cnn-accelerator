// Multiple Input Single Output (MISO) FIFO
module miso_fifo #(
    parameter int DEPTH = 32,  
    parameter int DATA_WIDTH = 8,
    parameter int DATA_LENGTH = 9,
    localparam ADDR_WIDTH = $clog2(DEPTH),
    parameter int INDEX = 0
)(
    input logic i_clk, i_nrst, i_clear, i_write_en, i_pop_en, i_r_pointer_reset,
    input logic [DATA_LENGTH-1:0][DATA_WIDTH-1:0] i_data,       
    input logic [DATA_LENGTH-1:0] i_valid,
    output logic [DATA_WIDTH-1:0] o_data,                          
    output logic o_empty, o_full, o_pop_valid       
);
    logic [ADDR_WIDTH-1:0] w_pointer, r_pointer;
    logic [DATA_WIDTH-1:0] fifo [DEPTH-1:0];

    logic write_en;
    assign write_en = i_write_en & !o_full;

    // Write data
    always @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            w_pointer <= 0;
        end else if (i_clear) begin
            w_pointer <= 0;
        end else if (write_en) begin
            for (int i = 0; i < DATA_LENGTH; i = i + 1) begin
                if (i_valid[i] == 1) begin
                    fifo[w_pointer + i] <= i_data[i];
                    w_pointer <= w_pointer + i + 1;
                end 
            end
        end
    end

    // Pop data
    always_ff @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst || i_r_pointer_reset) begin
            r_pointer <= 0;
            o_data <= 0;
            o_pop_valid <= 0;
        end else if (i_clear) begin
            r_pointer <= 0;
            o_data <= 0;
            o_pop_valid <= 0;
        end else if (i_pop_en && !o_empty) begin
            o_data <= fifo[r_pointer];
            r_pointer <= r_pointer + 1;
            o_pop_valid <= 1;
        end else begin
            o_data <= 0;
            o_pop_valid <= 0;
        end
    end

    // Status signals
    always_comb begin
        o_full = (w_pointer + 1) == r_pointer;
        o_empty = (w_pointer == r_pointer);
    end
endmodule
