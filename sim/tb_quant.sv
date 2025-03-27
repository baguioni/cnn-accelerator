`timescale 1ns / 1ps

module tb_quant;

parameter DATA_WIDTH = 8;

logic                    i_clk;
logic                    i_en;
logic                    i_store_reg;
logic                    i_nrst;
logic [  DATA_WIDTH-1:0] i_sh;
logic [2*DATA_WIDTH-1:0] i_m0;
logic [2*DATA_WIDTH-1:0] i_act;
logic [  DATA_WIDTH-1:0] o_act;
logic                    o_valid;

quant #(    
    .DATA_WIDTH(DATA_WIDTH)
) uut (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_en(i_en),
    .i_store_reg(i_store_reg),
    .i_sh(i_sh),
    .i_m0(i_m0),
    .i_act(i_act),
    .o_act(o_act),
    .o_valid(o_valid)
);

always #5 i_clk = ~i_clk;

integer input_file, output_file, r;
initial begin
    $dumpfile("tb.vcd");
    $dumpvars;

    input_file = $fopen("input.txt", "r");
    if (input_file == 0) begin
        $display("Error opening input file!");
        $finish;
    end

    output_file = $fopen("output.txt", "w");
    if (output_file == 0) begin
        $display("Error opening output file!");
        $finish;
    end

    i_clk = 0;
    i_nrst = 0;
    i_en = 0;
    i_store_reg = 0;
    i_sh = 0;
    i_m0 = 0;
    i_act = 0;

    #10;
    #5 i_nrst = 1;
    #10;

    while (!$feof(input_file)) begin
        i_en = 1;
        i_store_reg = 1;
        r = $fscanf(input_file, "%d, %d, %d\n", i_m0, i_sh, i_act);
        if (r != 3) begin
            $display("Error reading data from file!");
            $finish;
        end
        #10;
        i_en = 0;
        i_store_reg = 0;
        #10;
        $fwrite(output_file, "%h\n", o_act);
    end
    $fclose(input_file);
    i_en = 0;
    i_store_reg = 0;

    $display("Simulation completed: all tests done.");
    $fclose(output_file);

    #50;
    $finish;
end

endmodule