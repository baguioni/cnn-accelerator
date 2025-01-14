`timescale 1ns / 1ps
module tb_top;

    // Parameters
    localparam int DATA_WIDTH = 64;
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int DATA_LENGTH = 9;

    // Signals
    logic i_clk, i_nrst, i_en, i_reg_clear, i_sram_write_en;
    logic [DATA_WIDTH-1:0] i_data_in;
    logic [ADDR_WIDTH-1:0] i_write_addr, i_start_addr, i_addr_end, i_o_x, i_o_y, i_i_size, i_o_size;
    logic o_read_done, i_miso_pop_en, o_route_done;

    // File-related variables
    integer file, r;
    logic [DATA_WIDTH-1:0] mem_data;

    // Instantiate DUT
    top dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_sram_write_en(i_sram_write_en),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_start_addr(i_start_addr),
        .i_addr_end(i_addr_end),
        .o_read_done(o_read_done),
        .o_route_done(o_route_done),
        .i_o_x(i_o_x),
        .i_o_y(i_o_y),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size)
    );

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    // Testbench
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_top);

        // Initialize signals
        i_nrst = 0;
        i_en = 0;
        i_reg_clear = 0;
        i_sram_write_en = 0;
        i_write_addr = 0;
        i_data_in = 0;
        i_start_addr = 0;
        i_addr_end = 0;
        i_i_size = 5; // Example input size
        i_o_size = 3; // Example output size
        i_o_x = 0;
        i_o_y = 0;
        // Reset
        #10;
        i_nrst = 1;


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
            i_sram_write_en = 1;
            i_data_in = mem_data;
            #10; // Wait for one clock cycle
            i_write_addr = i_write_addr + 1;
        end
        i_sram_write_en = 0;
        $fclose(file);

        // Set read parameters
        i_start_addr = 0; // Start address for tile reading
        i_addr_end = i_write_addr - 1; // Last address written

        #10;
        i_en = 1;

        #750;

        $finish;
    end
endmodule
