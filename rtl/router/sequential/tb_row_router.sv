module tb_row_router;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam DATA_LENGTH = 9;
    localparam ADDR_WIDTH = 8;
    localparam KERNEL_SIZE = 3;
    localparam PEEK_WIDTH = 4;

    // Testbench Signals
    logic i_clk, i_nrst, i_en, i_reg_clear, i_pop_en, i_peek_en;
    logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_size, i_start_addr;
    logic [0:PEEK_WIDTH-1] i_addr_hit;
    logic [0:PEEK_WIDTH-1][DATA_WIDTH-1:0] o_peek_addr;
    logic i_data_hit, i_miso_pop_en;
    logic [0:PEEK_WIDTH-1][DATA_WIDTH-1:0] i_data;

    // Instantiate DUT
    row_router #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE),
        .PEEK_WIDTH(PEEK_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_i_size(i_i_size),
        .i_start_addr(i_start_addr),
        .i_pop_en(i_pop_en),
        .i_addr_hit(i_addr_hit),
        .i_peek_en(i_peek_en),
        .o_peek_addr(o_peek_addr),
        .i_data_hit(i_data_hit),
        .i_miso_pop_en(i_miso_pop_en),
        .i_data(i_data)
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
        i_en = 0;
        i_reg_clear = 0;
        i_pop_en = 0;
        i_peek_en = 0;
        i_data_hit = 0;
        i_miso_pop_en = 0;
        i_o_x = 0;
        i_o_y = 0;
        i_i_size = 0;
        i_start_addr = 0;
        i_addr_hit = 4'b0;
        for (int i = 0; i < PEEK_WIDTH; i++) begin
            i_data[i] = {DATA_WIDTH{1'b0}};
        end

        // Reset
        #10;
        i_nrst = 1;

        // Initialize parameters
        i_i_size = 5; // Example input size
        i_start_addr = 0; // Example starting address
        i_o_x = 0;
        i_o_y = 0;

        // Enable address generation
        i_en = 1;
        #50; // Wait for address generation
        i_en = 0;



        // Peek addresses
        i_peek_en = 1;
        #10;
        $display("Peeked Addresses:");
        for (int i = 0; i < PEEK_WIDTH; i++) begin
            $display("Address[%0d]: %0h", i, o_peek_addr[i]);
        end
        i_peek_en = 0;

        // Pop specific data from `mpp_fifo`
        i_pop_en = 1;
        i_addr_hit = 4'b1000; // Pop the 4th element
        #10;
        i_pop_en = 0;

                // Provide data for `miso_fifo`
        for (int i = 0; i < PEEK_WIDTH; i++) begin
            i_data[i] = i + 1; // Example data
        end
        i_data_hit = 1; // Enable write to `miso_fifo`
        #10;
        i_data_hit = 0;

        // Pop data from `miso_fifo`
        i_miso_pop_en = 1;
        #10;
        i_miso_pop_en = 0;

        // Clear registers
        i_reg_clear = 1;
        #10;
        i_reg_clear = 0;

        // Finish simulation
        #20;
        $finish;
    end
endmodule
