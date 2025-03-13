`timescale 1ns / 1ps
`include "rtl/global.svh"
`include "tb_top.svh"

module tb_top;
    localparam int SRAM_DATA_WIDTH = `SPAD_DATA_WIDTH;
    localparam int ADDR_WIDTH = `ADDR_WIDTH;
    localparam int DATA_WIDTH = `DATA_WIDTH;

    int counter = 0; // counter initialization

    // File-related variables
    integer file, r, output_file, o_file, go_file, o_l, go_l;
    logic [SRAM_DATA_WIDTH-1:0] mem_data;
    logic [DATA_WIDTH*2-1:0] expected, golden;

    // Signals
    logic i_clk, i_nrst, i_reg_clear, i_write_en, i_route_en;
    logic [1:0] p_mode;
    logic [SRAM_DATA_WIDTH-1:0] i_data_in;
    logic [ADDR_WIDTH-1:0] i_write_addr;
    logic [ADDR_WIDTH-1:0] i_i_start_addr, i_i_addr_end;
    logic [ADDR_WIDTH-1:0] i_size, o_size, stride, i_c_size, i_c; 
    logic [ADDR_WIDTH-1:0] i_w_start_addr, i_w_addr_offset, i_route_size;

    logic [DATA_WIDTH*2-1:0] o_ofmap;
    logic o_ofmap_valid, o_done;

    logic i_spad_select;

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
        .i_i_c_size(i_c_size),
        .i_i_c(i_c),
        .i_stride(stride),
        .i_w_start_addr(i_w_start_addr),
        .i_w_addr_offset(i_w_addr_offset),
        .i_route_size(i_route_size),
        .o_ofmap(o_ofmap),
        .o_ofmap_valid(o_ofmap_valid),
        .o_done(o_done)
    );

    initial begin
        // Iverilog
        // $dumpfile("tb.vcd");
        // $dumpvars(0, tb_top);

        // VCS 
        $vcdplusfile("tb_top.vpd");
        $vcdpluson;
        $sdf_annotate("../mapped/top.sdf", dut);
        // Prime Time        
        $dumpfile("tb_top.dump");
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
        i_size = `INPUT_SIZE;
        i_c_size = `CHANNEL_SIZE;
        i_c = `CHANNEL;
        o_size = `OUTPUT_SIZE;
        stride = `STRIDE;
        p_mode = `PRECISION;

        // // Retrieve command-line arguments
        // if (!$value$plusargs("i_i_size=%d", i_size)) i_size = 10;
        // if (!$value$plusargs("i_c_size=%d", i_c_size)) i_c_size = 2;
        // if (!$value$plusargs("i_c=%d", i_c)) i_c = 0;
        // if (!$value$plusargs("i_o_size=%d", o_size)) o_size = 8;
        // if (!$value$plusargs("i_stride=%d", stride)) stride = 1;
        // if (!$value$plusargs("i_p_mode=%d", p_mode)) p_mode = 2'b00;

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

        while(i_route_en == 1 & o_done != 1) begin // while SIG = "1"
            @(posedge i_clk); // when clock signal gets high
            counter++; // increase counter by 1
        end
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
            $display("Total cycles: %d", counter);
            $fclose(output_file);
            $finish;
        end
    end

    final begin
        o_file = $fopen("output.txt", "r");
        go_file = $fopen("golden_output.txt", "r");
        if (o_file == 0 || go_file == 0) begin
            $display("Error opening output file!");
            $finish;
        end

        $display("Verifying output against golden output");
        $display("Input Size: %d, Output Size %d, Channel Size: %d, Channel: %d, Stride: %d, Precision Mode: %d", i_size, o_size, i_c_size, i_c, stride, p_mode);

        while (!feof(o_file) || !feof(go_file)) begin
            o_l = $fscanf(g," %d ", expected );
            go_l = $fscanf(g2," %d ", golden);
        end

        if (expected == golden) begin
            $display("OUTPUT MATCH %h (reference) == %h (golden)", expected, golden);
        end else begin
            $display("OUTPUT MISMATCH %h (reference) != %h (golden)", expected, golden);
        end

        $display("Verification complete.");
        $fclose(o_file);
        $fclose(go_file);
        $finish;
    end
endmodule
