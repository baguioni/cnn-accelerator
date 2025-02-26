module fifo #(
    parameter int DEPTH = 8,  
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
    input logic i_clk, i_nrst, i_clear, i_write_en, i_pop_en,
    input logic [DATA_WIDTH-1:0] i_data_in,                
    output logic [DATA_WIDTH-1:0] o_pop_out,            
    output logic [DATA_WIDTH-1:0] o_peek_data,                
    output logic o_empty, o_full            
);
    logic [ADDR_WIDTH-1:0] w_pointer, r_pointer;
    logic [DATA_WIDTH-1:0] fifo [DEPTH-1:0];

    initial begin
        $monitor("[%0t] [FIFO] i_write_en=%0b i_data_in=0x%0h i_pop_en=%0b o_pop_out=0x%0h o_peek_data=0x%0h o_empty=%0b o_full=%0b",
            $time, i_write_en, i_data_in, i_pop_en, o_pop_out, o_peek_data, o_empty, o_full);
    end

    // Write data
    always_ff @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            w_pointer <= 0;
        end else if (i_clear) begin
            w_pointer <= 0;
        end else if (i_write_en & !o_full) begin
            fifo[w_pointer] <= i_data_in;
            w_pointer <= w_pointer + 1;
        end
    end

    // Pop data
    always_ff @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            r_pointer <= 0;
            o_pop_out <= 0;
        end else if (i_clear) begin
            r_pointer <= 0;
            o_pop_out <= 0;
        end else if (i_pop_en) begin
            o_pop_out <= fifo[r_pointer];
            r_pointer <= r_pointer + 1;
        end
    end

    // Peek data
    always_comb begin
        if (!o_empty) begin
            o_peek_data = fifo[r_pointer];
        end else begin
            o_peek_data = {DATA_WIDTH{1'b0}};
        end
    end

    // Status signals
    always_comb begin
        o_full = (w_pointer + 1) == r_pointer;
        o_empty = (w_pointer == r_pointer);
    end
endmodule
