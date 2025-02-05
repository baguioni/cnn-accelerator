`timescale 1ns / 1ps

module tb_address_generator;

    // Parameters
    parameter int ADDR_WIDTH = 8;
    parameter int ADDR_LENGTH = 9;
    parameter int KERNEL_SIZE = 3;

    // DUT Inputs
    logic i_clk, i_nrst, i_en, i_reg_clear;
    logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_size, i_start_addr;

    // DUT Outputs
    logic o_valid;
    logic [0:ADDR_LENGTH-1][ADDR_WIDTH-1:0] o_addr;

    // Instantiate DUT
    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ADDR_LENGTH(ADDR_LENGTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_i_size(i_i_size),
        .i_start_addr(i_start_addr),
        .o_valid(o_valid),
        .o_addr(o_addr)
    );

    // Clock Generation
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
        i_o_x = 0;
        i_o_y = 0;
        i_i_size = 0;
        i_start_addr = 0;

        // Apply reset
        #10;
        i_nrst = 1;

        // Configure inputs
        i_start_addr = 6'd0;
        i_o_x = 6'd0;
        i_o_y = 6'd0;
        i_i_size = 6'd5;

        // Enable the module
        i_en = 1;
        #10;
        i_en = 0;

        // Clear registers
        i_reg_clear = 1;
        #10;
        i_reg_clear = 0;

        // End simulation
        #50;
        $finish;
    end

endmodule
