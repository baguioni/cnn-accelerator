module tb_mpp_fifo;

    // Parameters
    localparam DEPTH = 16;
    localparam DATA_WIDTH = 8;
    localparam DATA_LENGTH = 9;
    localparam PEEK_WIDTH = 4;

    // Signals
    logic i_clk, i_nrst, i_clear, i_write_en, i_pop_en, i_peek_en;
    logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] i_data_in;
    logic [0:PEEK_WIDTH-1] i_data_hit;
    logic [0:PEEK_WIDTH-1][DATA_WIDTH-1:0] o_peek_data;
    logic [0:PEEK_WIDTH-1] o_valid_data;
    logic o_peek_valid, o_empty, o_full;

    // Instantiate DUT
    mpp_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH),
        .PEEK_WIDTH(PEEK_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_clear),
        .i_write_en(i_write_en),
        .i_data_in(i_data_in),
        .i_pop_en(i_pop_en),
        .i_data_hit(i_data_hit),
        .i_peek_en(i_peek_en),
        .o_peek_data(o_peek_data),
        .o_valid_data(o_valid_data),
        .o_peek_valid(o_peek_valid),
        .o_empty(o_empty),
        .o_full(o_full)
    );

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    // Testbench
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
        // Initialization
        i_nrst = 0;
        i_clear = 0;
        i_write_en = 0;
        i_pop_en = 0;
        i_peek_en = 0;
        i_data_in = 0;
        i_data_hit = 4'b0000;

        // Reset
        #10;
        i_nrst = 1;


        i_write_en = 1;
        for (int j = 0; j < DATA_LENGTH; j++) begin
            i_data_in[j] = (j + 1); // Example data
        end
        #10; // Wait for one clock cycle
        i_write_en = 0;

        // Peek the first 4 elements
        #10;
        i_peek_en = 1;
        #10;
        for (int i = 0; i < PEEK_WIDTH; i++) begin
            $display("Peeked Data[%0d]: %0h (Valid: %0b)", i, o_peek_data[i], o_valid_data[i]);
        end
        i_peek_en = 0;

        // Pop one element based on data hit
        #10;
        i_pop_en = 1;
        i_data_hit = 4'b1000; // Example: Pop the 4th peeked element
        #10;
        i_pop_en = 0;

        // Check FIFO status
        #10;
        $display("Empty: %0b, Full: %0b, Peek Valid: %0b", o_empty, o_full, o_peek_valid);

        // Finish simulation
        #20;
        $finish;
    end
endmodule
