module sipo_fifo #(
    parameter int DEPTH=8, 
    parameter int DATA_WIDTH=16,
    parameter int ADDR_WIDTH=$clog2(DEPTH)
)(
    input  logic i_clk, i_nrst, i_clear, i_wen, i_ren,
    input  logic [DATA_WIDTH-1:0] i_data_in,
    output logic [DEPTH*DATA_WIDTH-1:0] o_data_out,
    output logic o_empty, o_full
);
    logic [ADDR_WIDTH:0] cntr;
    logic [ADDR_WIDTH-1:0] wptr, rptr;
    logic [DATA_WIDTH-1:0] fifo [DEPTH];

    // Push data
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            wptr <= 0;
            cntr <= 0;
        end else if (i_clear) begin
            wptr <= 0;
            cntr <= 0;
        end else if (i_wen && !o_full) begin
            fifo[wptr] <= i_data_in;
            wptr <= wptr + 1;
            cntr <= (cntr < DEPTH)? cntr + 1 : 0;
        end
    end

    // Pop data
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            rptr <= 0;
            o_data_out <= 0;
        end else if (i_clear) begin
            rptr <= 0;
            o_data_out <= 0;
        end else if (i_ren && o_full) begin
            rptr <= rptr + 8;
            for (int i = 0; i < DEPTH; i++) begin
                o_data_out |= (fifo[i] << (i * DATA_WIDTH));
            end
            cntr <= 0;
        end
    end

    always_comb begin
        o_full  = (cntr == DEPTH);
        o_empty = (cntr == 0);
    end

    genvar j;
    generate
        for (j=0; j<DEPTH; j++) begin
            logic [DATA_WIDTH-1:0] fifo_entry;
            assign fifo_entry = fifo[j]; 
        end
    endgenerate

endmodule