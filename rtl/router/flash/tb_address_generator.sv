module address_generator_tb;

    // Parameters
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 8;
    localparam DATA_LENGTH = 9;
    localparam KERNEL_SIZE = 3;

    // Inputs
    logic i_clk, i_nrst, i_en, i_reg_clear;
    logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_start_addr, i_i_size;

    // Outputs
    logic o_valid;
    logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] o_addr;

    // Instantiate the DUT
    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_start_addr(i_start_addr),
        .i_i_size(i_i_size),
        .o_valid(o_valid),
        .o_addr(o_addr)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns period
    end

    // Testbench logic
    initial begin
        // Initialize inputs
        i_nrst = 0;
        i_en = 0;
        i_reg_clear = 0;
        i_o_x = 0;
        i_o_y = 0;
        i_start_addr = 6'd0;
        i_i_size = 6'd5;

        // Reset the DUT
        #10 i_nrst = 1;

        // Case 1: i_o_x = 0, i_o_y = 0
        #10 i_en = 1;
        i_o_x = 0;
        i_o_y = 0;
        i_start_addr = 6'd0;

        #20 i_en = 0;
        
        // Case 2: i_o_x = 1, i_o_y = 1
        #10 i_en = 1;
        i_o_x = 1;
        i_o_y = 1;

        // Wait for valid signal
        wait (o_valid == 1);

        #10 $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
    end

endmodule
