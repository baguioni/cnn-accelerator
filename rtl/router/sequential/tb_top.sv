`timescale 1ns / 1ps

module tb_top;
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    // File-related variables
    integer file, r;
    logic [SRAM_DATA_WIDTH-1:0] mem_data;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    // Signals
    logic i_clk, i_nrst, i_reg_clear, i_write_en, i_route_en;
    logic [1:0] i_p_mode;
    logic [SRAM_DATA_WIDTH-1:0] i_data_in;
    logic [ADDR_WIDTH-1:0] i_write_addr;
    logic [ADDR_WIDTH-1:0] i_i_start_addr, i_i_addr_end;
    logic [ADDR_WIDTH-1:0] i_i_size, i_o_size, i_stride; 
    logic [ADDR_WIDTH-1:0] i_w_start_addr, i_w_addr_offset, i_route_size;

    logic [1:0] i_sram_select;

    top dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_p_mode(i_p_mode),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_sram_select(i_sram_select),
        .i_write_en(i_write_en),
        .i_route_en(i_route_en),
        .i_i_start_addr(i_i_start_addr),
        .i_i_addr_end(i_i_addr_end),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size),
        .i_stride(i_stride),
        .i_w_start_addr(i_w_start_addr),
        .i_w_addr_offset(i_w_addr_offset),
        .i_route_size(i_route_size)
    );

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_top);
    end

    // Testbench
    initial begin
        // Initialize signals
        i_nrst = 0;
        i_reg_clear = 0;
        i_sram_select = 0;
        i_write_addr = 0;
        i_data_in = 0;
        i_i_start_addr = 0;
        i_i_addr_end = 0;
        i_i_size = 5;
        i_o_size = 3;
        i_stride = 1;
        i_w_start_addr = 0;
        i_w_addr_offset = 1;
        i_route_size = 9;
        i_route_en = 0;
        i_p_mode = 2'b01;
        #10;
        i_nrst = 1;

        // Write to weight SRAM
        file = $fopen("sram.mem", "r");
        if (file == 0) begin
            $display("Error opening file!");
            $finish;
        end

        while (!$feof(file)) begin
            r = $fscanf(file, "%h\n", mem_data);
            if (r != 1) begin
                $display("Error reading data from file!");
                $finish;
            end
            i_write_en = 1;
            i_sram_select = 0;
            i_data_in = mem_data;
            #10; // Wait for one clock cycle
            i_write_addr = i_write_addr + 1;
        end
        i_i_addr_end = i_write_addr - 1;
        i_write_en = 0;
        i_write_addr = 0;
        $fclose(file);

        // Write to input SRAM
        file = $fopen("sram.mem", "r");
        if (file == 0) begin
            $display("Error opening file!");
            $finish;
        end

        while (!$feof(file)) begin
            r = $fscanf(file, "%h\n", mem_data);
            if (r != 1) begin
                $display("Error reading data from file!");
                $finish;
            end
            i_write_en = 1;
            i_sram_select = 1;
            i_data_in = mem_data;
            #10; // Wait for one clock cycle
            i_write_addr = i_write_addr + 1;
        end
        i_write_en = 0;
        $fclose(file);
    
        #20;
        i_route_en = 1;
        #1000;
        $finish;
    end
endmodule