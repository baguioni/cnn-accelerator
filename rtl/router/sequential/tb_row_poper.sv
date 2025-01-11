`timescale 1ns/1ps

module tb_row_poper;

    // Parameters
    parameter int ROUTER_COUNT = 4;

    // Signals
    logic i_clk, i_nrst, i_reg_clear, i_en;
    logic [ROUTER_COUNT-1:0] o_rr_en;

    // DUT instantiation
    row_poper #(
        .ROUTER_COUNT(ROUTER_COUNT)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_en(i_en),
        .o_rr_en(o_rr_en)
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
        i_reg_clear = 0;
        i_en = 0;

        // Reset the design
        #10;
        i_nrst = 1;
        
        // Test case 1: Reset functionality
        #10;

        // Test case 2: Enable the module and observe behavior
        i_en = 1;
        repeat (ROUTER_COUNT + 1) begin
            #10;
            $display("o_rr_en = %b", o_rr_en);
        end
        #50;
        // Test case 3: Clear the registers
        i_reg_clear = 1;
        #10;
        i_reg_clear = 0;

        // Test case 4: Enable and test rollover
        repeat (ROUTER_COUNT + 2) begin
            #10;
            $display("o_rr_en = %b", o_rr_en);
        end

        $finish;
    end

endmodule
