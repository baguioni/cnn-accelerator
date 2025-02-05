`timescale 1ns/1ps

module router_controller_tb;

    // Parameters
    parameter ROW_COUNT = 3;
    parameter ADDR_WIDTH = 8;

    // Testbench Signals
    reg i_clk;
    reg i_nrst;
    reg i_en;
    reg i_reg_clear;

    reg [ADDR_WIDTH-1:0] i_start_addr;
    reg [ADDR_WIDTH-1:0] i_o_size;

    wire [ROW_COUNT-1:0] o_row_id;
    wire [ADDR_WIDTH-1:0] o_o_x, o_o_y;

    wire o_ag_en, o_ac_en, o_tile_read_en, o_pop_en;
    wire o_done;

    reg i_addr_empty;
    reg i_data_empty;

    // Instantiate the DUT
    router_controller #(
        .ROW_COUNT(ROW_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_start_addr(i_start_addr),
        .i_o_size(i_o_size),
        .o_row_id(o_row_id),
        .o_o_x(o_o_x),
        .o_o_y(o_o_y),
        .o_ag_en(o_ag_en),
        .o_ac_en(o_ac_en),
        .o_tile_read_en(o_tile_read_en),
        .o_pop_en(o_pop_en),
        .i_addr_empty(i_addr_empty),
        .i_data_empty(i_data_empty),
        .o_done(o_done)
    );

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    // Testbench
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;

        // Initialize signals
        i_nrst = 0;
        i_en = 0;
        i_reg_clear = 0;
        i_start_addr = 0;
        i_o_size = 3; // 4x4 output feature map
        i_addr_empty = 0;
        i_data_empty = 0;

        // Reset
        #10;
        i_nrst = 1;

        // Enable the controller
        #10;
        i_en = 1;

        // Simulate the operation
        #50;
        i_addr_empty = 1; // Address queue becomes empty

        #20;
        i_data_empty = 1; // Data queue becomes empty

        #30;

        // Clear the registers
        #10;
        // i_reg_clear = 1;

        #10;
        // i_reg_clear = 0;

        // Re-enable the controller for another round
        #10;
        i_en = 1;

        #100;

        $finish;
    end

endmodule
