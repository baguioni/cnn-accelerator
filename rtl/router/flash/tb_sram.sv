module sram_rw_tb;

    // Parameters
    parameter int DEPTH = 64;
    parameter int DATA_WIDTH = 8;
    parameter int WRITE_WIDTH = 4;
    parameter int READ_WIDTH = 2;
    parameter int ADDR_WIDTH = $clog2(DEPTH * WRITE_WIDTH);
    parameter int INPUT_WIDTH = DATA_WIDTH * WRITE_WIDTH;
    parameter int OUTPUT_WIDTH = DATA_WIDTH * READ_WIDTH;

    // Inputs
    logic i_clk, i_nrst, i_write_en, i_read_en;
    logic [0:WRITE_WIDTH-1][DATA_WIDTH-1:0] i_data_in;
    logic [ADDR_WIDTH-1:0] i_write_addr;
    logic [0:READ_WIDTH-1][ADDR_WIDTH-1:0] i_read_addr;

    // Outputs
    logic [0:READ_WIDTH-1][DATA_WIDTH-1:0] o_data_out;

    // Instantiate the DUT
    sram #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .WRITE_WIDTH(WRITE_WIDTH),
        .READ_WIDTH(READ_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_write_en(i_write_en),
        .i_read_en(i_read_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_read_addr(i_read_addr),
        .o_data_out(o_data_out)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // Clock period = 10 ns
    end

    // Testbench logic
    initial begin
        // Initialize inputs
        i_nrst = 0;
        i_write_en = 0;
        i_read_en = 0;
        i_data_in = '{8'h00,8'h00,8'h00,8'h00}; // Initialize each element to 0
        i_write_addr = '0;
        i_read_addr = '{0,0}; // Initialize each address to 0

        // Apply reset
        #10 i_nrst = 1;

        // Perform a write operation
        #10 i_write_en = 1;
        i_write_addr = 0; // Start writing at address 10
        i_data_in = '{8'hA1, 8'hB2, 8'hC3, 8'hD4}; // 4 bytes of data
        #10 i_write_en = 0;

        // Perform a read operation
        #10 i_read_en = 1;
        i_read_addr = '{1, 0}; // Random addresses to read
        #10 i_read_en = 0;

        // Wait and finish
        #50 $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
    end

endmodule
