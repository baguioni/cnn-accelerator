module miso_fifo_tb;

    // Parameters
    localparam DEPTH = 32;
    localparam DATA_WIDTH = 8;
    localparam DATA_LENGTH = 9;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Inputs
    logic i_clk, i_nrst, i_clear, i_write_en, i_pop_en;
    logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] i_data;
    logic [DATA_LENGTH-1:0] i_valid;

    // Outputs
    logic [DATA_WIDTH-1:0] o_data;
    logic o_empty, o_full;

    // Instantiate the DUT
    miso_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_clear),
        .i_write_en(i_write_en),
        .i_pop_en(i_pop_en),
        .i_data(i_data),
        .i_valid(i_valid),
        .o_data(o_data),
        .o_empty(o_empty),
        .o_full(o_full)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns clock period
    end

    // Testbench logic
    initial begin
        // Initialize inputs
        i_nrst = 0;
        i_clear = 0;
        i_write_en = 0;
        i_pop_en = 0;
        i_data = '0;
        i_valid = '0;

        // Apply reset
        #10 i_nrst = 1;

        // Perform a write operation
        #10 i_write_en = 1;
        i_data = '{8'hA1, 8'hB2, 8'hC3, 8'hD4, 8'hE5, 8'hF6, 8'h07, 8'h18, 8'h29};
        i_valid = 9'b000011111; // All inputs valid

        #10 i_write_en = 0;

        // Wait a few cycles
        #20;

        #10 i_write_en = 1;
        i_data = '{8'h01, 8'hB2, 8'hC3, 8'hD4, 8'hE5, 8'hF6, 8'h07, 8'h18, 8'h29};
        i_valid = 9'b1; // All inputs valid

        #10 i_write_en = 0;
        i_pop_en = 1;
        #20;

        // Finish simulation
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
    end

endmodule
