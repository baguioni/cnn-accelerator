`timescale 1ns/1ps

module weight_top_tb;

    // Parameters
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int DATA_WIDTH = 8;
    localparam int DATA_LENGTH = 8;

    // Testbench signals
    logic clk, nrst;
    logic en, reg_clear;
    logic sram_write_en, route_en, data_out_en, route_reuse;

    logic [SRAM_DATA_WIDTH-1:0] data_in;
    logic [ADDR_WIDTH-1:0] write_addr;

    logic [ADDR_WIDTH-1:0] start_addr, addr_offset;
    logic [ADDR_WIDTH-1:0] route_size;
    logic route_ready;

    logic [DATA_WIDTH-1:0] data_out;
    logic data_valid;
            integer file, r;
                    reg [SRAM_DATA_WIDTH-1:0] mem_data;

    // DUT instantiation
    weight_top dut (
        .i_clk(clk),
        .i_nrst(nrst),
        .i_reg_clear(reg_clear),
        .i_fifo_clear(),
        .i_route_reuse(route_reuse),
        .i_sram_write_en(sram_write_en),
        .i_route_en(route_en),
        .i_data_out_en(data_out_en),
        .i_data_in(data_in),
        .i_write_addr(write_addr),
        .i_start_addr(start_addr),
        .i_addr_offset(addr_offset),
        .i_route_size(route_size),
        .o_route_ready(route_ready),
        .o_route_done(),
        .o_data(data_out),
        .o_data_valid(data_valid)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    // Testbench logic
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars();
        // Initialize signals
        nrst = 0;
        en = 0;
        reg_clear = 0;
        sram_write_en = 0;
        route_en = 0;
        data_in = 0;
        data_out_en = 0;
        write_addr = 0;
        start_addr = 8'h00;
        addr_offset = 8'd1;
        route_reuse = 0;
        route_size = 8'h09;

        // Reset the DUT
        #10 nrst = 1;

        // Clear registers
        reg_clear = 1;
        #10 reg_clear = 0;

        // Open and read the .mem file


        file = $fopen("sram.mem", "r");
        if (file == 0) begin
            $display("Error opening file!");
            $finish;
        end

        // Write data to SRAM
        while (!$feof(file)) begin
            r = $fscanf(file, "%h\n", mem_data);
            if (r != 1) begin
                $display("Error reading data from file!");
                $finish;
            end
            sram_write_en = 1;
            data_in = mem_data;
            #10; // Wait for one clock cycle
            write_addr = write_addr + 1;
        end
        sram_write_en = 0;
        $fclose(file);

        // Enable routing
        #10;
        route_en = 1;
        #50;
        route_en = 0;
        data_out_en = 1;

        // End simulation
        #100;

        route_reuse = 1;
        #10;
        route_reuse = 0;
        #150;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | Route Ready: %b | Data Out: %h | Data Valid: %b", 
                 $time, route_ready, data_out, data_valid);
    end

endmodule
