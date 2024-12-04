module tb_row_router;
    // Parameters
    parameter int DATA_WIDTH = 8;
    parameter int ADDR_WIDTH = 6;
    parameter int FIFO_DEPTH = 16;

    // Testbench signals
    logic clk;
    logic nrst;
    logic en, reg_clear, stall_en;
    logic [ADDR_WIDTH-1:0] k_size, k_num, i_size;
    logic [ADDR_WIDTH-1:0] o_x, o_y, start_addr;
    logic valid_addr;
    logic [DATA_WIDTH-1:0] data_in;
    logic [ADDR_WIDTH-1:0] current_addr;
    logic ag_done;

    // Instantiate DUT
    row_router #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .i_clk(clk),
        .i_nrst(nrst),
        .i_en(en),
        .i_reg_clear(reg_clear),
        .i_stall_en(stall_en),
        .i_k_size(k_size),
        .i_k_num(k_num),
        .i_i_size(i_size),
        .i_o_x(o_x),
        .i_o_y(o_y),
        .i_start_addr(start_addr),
        .o_ag_done(ag_done),
        .i_valid_addr(valid_addr),
        .i_data_in(data_in),
        .i_addr(current_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
                $dumpfile("tb.vcd");
        $dumpvars;
        // Initialize signals
        nrst = 0;
        en = 0;
        reg_clear = 0;
        stall_en = 0;
        k_size = 3;
        k_num = 9;
        i_size = 5;
        o_x = 0;
        o_y = 0;
        start_addr = 0;
        valid_addr = 0;
        data_in = 0;
        current_addr = 0;

        // Reset sequence
        #10 nrst = 1;
        #10 reg_clear = 1;
        #10 reg_clear = 0;

        // Enable the module
        #10 en = 1;
        // Wait for address generator to finish
        wait (ag_done);

        for (int i = 0; i < 16; i++) begin
            current_addr = i; // Simulate sequential addresses
            valid_addr = 1;
            data_in = i; // Simulate random data input
            #10;
        end

        // End simulation
        #50 $finish;
    end

    // // Monitor outputs
    // initial begin
    //     $monitor("Time: %0t | ag_done: %b | fifo_addr_peek: %h | fifo_data_full: %b",
    //              $time, ag_done, dut.fifo_addr_peek, dut.fifo_data_full);
    // end
endmodule
