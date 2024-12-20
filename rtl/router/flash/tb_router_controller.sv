`timescale 1ns/1ps

module router_controller_tb;

    // Parameters
    parameter SA_HEIGHT = 4;
    parameter KERNEL_SIZE = 3;
    parameter ADDR_WIDTH = 6;
    localparam SA_BITS = $clog2(SA_HEIGHT);

    // Inputs
    reg i_clk;
    reg i_nrst;
    reg i_en;
    reg i_reg_clear;
    reg i_compute_done;
    reg [ADDR_WIDTH-1:0] i_start_addr;
    reg [ADDR_WIDTH-1:0] i_o_size;

    // Outputs
    wire [SA_BITS-1:0] o_row_number;
    wire [ADDR_WIDTH-1:0] o_o_x;
    wire [ADDR_WIDTH-1:0] o_o_y;
    wire o_done;

    // Instantiate the DUT
    router_controller #(
        .SA_HEIGHT(SA_HEIGHT),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_compute_done(i_compute_done),
        .i_start_addr(i_start_addr),
        .i_o_size(i_o_size),
        .o_row_number(o_row_number),
        .o_o_x(o_o_x),
        .o_o_y(o_o_y),
        .o_done(o_done)
    );

    // Clock generation
    always #5 i_clk = ~i_clk; // 10ns clock period

    // Test sequence
    initial begin
        // Initialize inputs
        i_clk = 0;
        i_nrst = 0;
        i_en = 0;
        i_reg_clear = 0;
        i_compute_done = 0;
        i_start_addr = 0;
        i_o_size = 4; // Set output size to 4x4

        // Reset the DUT
        #10 i_nrst = 1;
        #10 i_nrst = 0;
        #10 i_nrst = 1;

        // Enable the controller and observe behavior
        #10 i_en = 1;
        repeat (SA_HEIGHT * 4 * 4) begin
            #10;
        end

        // Simulate compute_done signal
        #10 i_compute_done = 1;
        #10 i_compute_done = 0;

        // Clear the registers
        #10 i_reg_clear = 1;
        #10 i_reg_clear = 0;

        // Continue operation
        repeat (SA_HEIGHT * 4 * 4) begin
            #10;
        end

        // Stop simulation
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
    end

endmodule
