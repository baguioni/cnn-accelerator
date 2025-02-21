`timescale 1ns / 1ps

module tb_sram;
    // Parameters
    parameter int ADDR_WIDTH = 16;
    parameter int DATA_WIDTH = 64;

    // Signals
    logic i_clk;
    logic i_nrst;
    logic i_write_en;
    logic i_read_en;
    logic [DATA_WIDTH-1:0] i_data_in;
    logic [ADDR_WIDTH-1:0] i_write_addr;
    logic [ADDR_WIDTH-1:0] i_read_addr;
    logic [DATA_WIDTH-1:0] o_data_out;
    logic o_data_out_valid;

    // DUT (Device Under Test)
    sram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_write_en(i_write_en),
        .i_read_en(i_read_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_read_addr(i_read_addr),
        .o_data_out(o_data_out),
        .o_data_out_valid(o_data_out_valid)
    );

    // Clock Generation (50MHz -> 20ns period)
    always #10 i_clk = ~i_clk;

    // Testbench Procedure
    initial begin
        // VCD Waveform Dump
        $dumpfile("tb.vcd");
        $dumpvars;

        // Initialize signals
        i_clk = 0;
        i_nrst = 0;
        i_write_en = 0;
        i_read_en = 0;
        i_data_in = 0;
        i_write_addr = 0;
        i_read_addr = 0;



        // Reset the SRAM
        #20 i_nrst = 1;
        #20;

        for (int i = 0; i < 4; i++) begin
            i_write_en = 1;
            i_write_addr = i;
            i_data_in = 64'hDEADBEEF00000000 + i;
            #20;
        end
        i_write_en = 0;
        #20;

        // Read the data back
        for (int i = 0; i < 4; i++) begin
            i_read_en = 1;
            i_read_addr = i;
            #20;
            i_read_en = 0;
            #10;
        end

        #50 $finish;
    end
endmodule
