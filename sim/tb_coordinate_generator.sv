`timescale 1ns / 1ps

module tb_coordinate_generator;

    // Parameters
    parameter int ADDR_WIDTH = 8;

    // DUT Inputs
    logic i_clk, i_nrst, i_en, i_reg_clear;
    logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride, i_start_addr;

    // DUT Outputs
    logic [ADDR_WIDTH-1:0] o_o_x, o_o_y;
    logic o_done;

    // Instantiate DUT
    coordinate_generator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size),
        .i_stride(i_stride),
        .i_start_addr(i_start_addr),
        .o_o_x(o_o_x),
        .o_o_y(o_o_y),
        .o_done(o_done)
    );

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    // Testbench
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;

        // Initialize inputs
        i_nrst = 0;
        i_en = 0;
        i_reg_clear = 0;
        i_i_size = 0;
        i_o_size = 0;
        i_stride = 0;
        i_start_addr = 0;

        // Apply reset
        #10;
        i_nrst = 1;

        // Configure parameters
        i_i_size = 8'd5;
        i_o_size = 8'd3;
        i_stride = 8'd1;
        i_start_addr = 8'd0;

        // Start the generator
        i_en = 1;
        #100;
        i_en = 0;

        // Clear the registers
        i_reg_clear = 1;
        #10;
        i_reg_clear = 0;

        // Check output coordinates
        #50;
        assert(o_done) else $error("o_done should be 1 after completing coordinates");

        // End simulation
        #100;
        $finish;
    end

endmodule
