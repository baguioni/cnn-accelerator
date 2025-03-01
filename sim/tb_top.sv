`timescale 1ns / 1ps

module tb_top;
    localparam int SRAM_DATA_WIDTH = 64;
    localparam int ADDR_WIDTH = 8;
    localparam int DATA_WIDTH = 8;

    // File-related variables
    integer file, r, output_file;
    logic [SRAM_DATA_WIDTH-1:0] mem_data;

    // Signals
    logic i_clk, i_nrst, i_reg_clear, i_write_en, i_route_en;
    logic [1:0] p_mode;
    logic [SRAM_DATA_WIDTH-1:0] i_data_in;
    logic [ADDR_WIDTH-1:0] i_write_addr;
    logic [ADDR_WIDTH-1:0] i_i_start_addr, i_i_addr_end;
    logic [ADDR_WIDTH-1:0] i_size, o_size, stride; 
    logic [ADDR_WIDTH-1:0] i_w_start_addr, i_w_addr_offset, i_route_size;

    logic [DATA_WIDTH*2-1:0] o_ofmap;
    logic o_ofmap_valid, o_done;

    logic [1:0] i_spad_select;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk; // 10ns clock period

    top dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_p_mode(p_mode),
        .i_data_in(i_data_in),
        .i_write_addr(i_write_addr),
        .i_spad_select(i_spad_select),
        .i_write_en(i_write_en),
        .i_route_en(i_route_en),
        .i_i_start_addr(i_i_start_addr),
        .i_i_addr_end(i_i_addr_end),
        .i_i_size(i_size),
        .i_o_size(o_size),
        .i_stride(stride),
        .i_w_start_addr(i_w_start_addr),
        .i_w_addr_offset(i_w_addr_offset),
        .i_route_size(i_route_size),
        .o_ofmap(o_ofmap),
        .o_ofmap_valid(o_ofmap_valid),
        .o_done(o_done)
    );

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_top);
    end

    // Testbench initialization
    initial begin
        // Default values
        i_nrst = 0;
        i_reg_clear = 0;
        i_spad_select = 0;
        i_write_addr = 0;
        i_data_in = 0;
        i_i_start_addr = 0;
        i_i_addr_end = 0;
        i_w_start_addr = 0;
        i_w_addr_offset = 1;
        i_route_size = 9;
        i_route_en = 0;

        // Retrieve command-line arguments
        if (!$value$plusargs("i_i_size=%d", i_size)) i_size = 10;
        if (!$value$plusargs("i_o_size=%d", o_size)) o_size = 8;
        if (!$value$plusargs("i_stride=%d", stride)) stride = 1;
        if (!$value$plusargs("i_p_mode=%d", p_mode)) p_mode = 2'b00;

        #10;
        i_nrst = 1;

        // Open output file
        output_file = $fopen("output.txt", "w");
        if (output_file == 0) begin
            $display("Error opening output file!");
            $finish;
        end

        // Write to weight SRAM
        file = $fopen("kernel.txt", "r");
        if (file == 0) begin
            $display("Error opening file 1");
            $finish;
        end

        while (!$feof(file)) begin
            r = $fscanf(file, "%h\n", mem_data);
            if (r != 1) begin
                $display("Error reading data from file!");
                $finish;
            end
            i_write_en = 1;
            i_spad_select = 0;
            i_data_in = mem_data;
            #10; // Wait for one clock cycle
            i_write_addr = i_write_addr + 1;
        end
        
        i_write_en = 0;
        i_write_addr = 0;
        $fclose(file);

        // Write to input SRAM
        file = $fopen("ifmap.txt", "r");
        if (file == 0) begin
            $display("Error opening file 2");
            $finish;
        end

        while (!$feof(file)) begin
            r = $fscanf(file, "%h\n", mem_data);
            if (r != 1) begin
                $display("Error reading data from file!");
                $finish;
            end
            i_write_en = 1;
            i_spad_select = 1;
            i_data_in = mem_data;
            #10; // Wait for one clock cycle
            i_write_addr = i_write_addr + 1;
        end
        i_i_addr_end = i_write_addr - 1;
        i_write_en = 0;
        $fclose(file);
    
        #20;
        i_route_en = 1;
    end

    // Monitor and write to output file whenever o_ofmap_valid is high
    always @(posedge i_clk) begin
        if (o_ofmap_valid) begin
            $fwrite(output_file, "%h\n", o_ofmap);
        end
    end

    // Terminate simulation when o_done is high
    always @(posedge i_clk) begin
        if (o_done) begin
            $display("Simulation completed: o_done asserted.");
            $fclose(output_file);
            $finish;
        end
    end
endmodule
