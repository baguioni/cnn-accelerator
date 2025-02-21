`timescale 1ns / 1ps

module tb_output_router;

parameter int SPAD_ADDR_WIDTH = 8;
parameter int SPAD_DATA_WIDTH = 16;
parameter int ROUTER_COUNT = 5;
parameter int DATA_WIDTH = 8;
parameter int MEMBER_CNT = (SPAD_DATA_WIDTH+DATA_WIDTH-1)/DATA_WIDTH;
parameter int GROUP_CNT  = (ROUTER_COUNT+MEMBER_CNT-1)/MEMBER_CNT;

logic                                      i_clk;
logic                                      i_nrst;
logic                                      i_en;
logic [0:ROUTER_COUNT-1][DATA_WIDTH*2-1:0] i_ifmap;
logic [ROUTER_COUNT-1:0]                   i_valid;
logic [SPAD_DATA_WIDTH-1:0]                o_data_out;
logic                                      o_valid;

output_router #(
    .SPAD_ADDR_WIDTH(SPAD_ADDR_WIDTH),
    .SPAD_DATA_WIDTH(SPAD_DATA_WIDTH),
    .ROUTER_COUNT(ROUTER_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .MEMBER_CNT(MEMBER_CNT),
    .GROUP_CNT(GROUP_CNT)
) uut (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_en(i_en),
    .i_ifmap(i_ifmap),
    .i_valid(i_valid),
    .o_data_out(o_data_out),
    .o_valid(o_valid)
);

always #5 i_clk = ~i_clk;

initial begin
    $dumpfile("tb.vcd");
    $dumpvars;

    i_clk = 0;
    i_nrst = 0;
    i_en = 0;
    i_ifmap = 0;
    i_valid = 0;
    #10;
    
    #5 i_nrst = 1;
    
    #10;

    i_en = 1;
    i_valid = {ROUTER_COUNT{1'b1}};
    i_ifmap[0] = 16'h0001;
    i_ifmap[1] = 16'h0002;
    i_ifmap[2] = 16'h0003;
    i_ifmap[3] = 16'h0004;
    i_ifmap[4] = 16'h0005;
    #10;

    i_en = 0;
    #10;

    #50;
    $finish;
end

endmodule