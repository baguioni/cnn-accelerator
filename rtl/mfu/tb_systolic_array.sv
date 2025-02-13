`timescale 1ns/1ps

module tb_systolic_array;
    parameter D_WIDTH = 8;
    parameter S_WIDTH = 2;
    parameter S_HEIGHT = 2;

    logic i_clk, i_nrst, i_reg_clear, i_pe_en, i_psum_out_en;


    logic [0:S_HEIGHT-1][D_WIDTH-1:0] i_ifmap;
    logic [0:S_WIDTH-1][D_WIDTH-1:0] i_weight;
    logic [0:S_HEIGHT-1][D_WIDTH*2-1:0] o_ifmap;

    systolic_array #(
        .DATA_WIDTH(D_WIDTH),
        .S_WIDTH(S_WIDTH),
        .S_HEIGHT(S_HEIGHT)
    ) systolic_array_inst (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(i_reg_clear),
        .i_pe_en(i_pe_en),
        .i_relu_en(1'b0),
        .i_psum_out_en(i_psum_out_en),
        .i_ifmap(i_ifmap),
        .i_weight(i_weight),
        .o_ifmap(o_ifmap)
    );

    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
        
        i_nrst = 0;
        i_reg_clear = 0;
        i_pe_en = 0;
        i_psum_out_en = 0;
        i_ifmap[0] = 8'h00;
        i_ifmap[1] = 8'h00;
        i_weight[0] = 8'h00; 
        i_weight[1] = 8'h00;

        #10;
        i_nrst = 1;
        #10;
        i_nrst = 0;
        #10;
        i_nrst = 1;

        #20;
    
        i_ifmap[0] = 8'h01;
        i_ifmap[1] = 8'h00;
        i_weight[0] = 8'h01; 
        i_weight[1] = 8'h00;
        i_pe_en = 1;
        #10;
        i_ifmap[0] = 8'h02;
        i_ifmap[1] = 8'h03;
        i_weight[0] = 8'h03; 
        i_weight[1] = 8'h02;
        #10;
        i_ifmap[0] = 8'h00;
        i_ifmap[1] = 8'h04;
        i_weight[0] = 8'h00; 
        i_weight[1] = 8'h04;
        #30;
        i_pe_en = 0;
        #10;
        i_psum_out_en = 1;

        #40;
        $finish;
    end

endmodule
