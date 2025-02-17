module tb_row_router_controller;

    // Parameters
    parameter int ROUTER_COUNT = 4;
    parameter int ADDR_WIDTH = 8;

    // Testbench signals
    logic i_clk;
    logic i_nrst;
    logic i_reg_clear;
    logic i_en;
    logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_size;
    logic [0:ROUTER_COUNT-1][ADDR_WIDTH-1:0] o_x, o_y;
    logic o_rr_en;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    // DUT instantiation
    row_router_controller #(
        .ROUTER_COUNT(ROUTER_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_en(i_en),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_i_size(i_i_size),
        .o_x(o_x),
        .o_y(o_y),
        .o_rr_en(o_rr_en)
    );

    // Testbench logic
    initial begin
        // Initialize signals
        i_nrst = 0;
        i_reg_clear = 0;
        i_en = 0;
        i_o_x = 0;
        i_o_y = 3;
        i_i_size = 5;

        $dumpfile("tb.vcd");
        $dumpvars;

        // Reset the DUT
        #20;
        i_nrst = 1;

        // Start operation
        #10;
        i_en = 1;

        // Wait for o_rr_en to be asserted
        wait(o_rr_en == 1);

        // End simulation
        #10;
        $display("Simulation finished: o_rr_en is asserted.");
        $finish;
    end
endmodule
