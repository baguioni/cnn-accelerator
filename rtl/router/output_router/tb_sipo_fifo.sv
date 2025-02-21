`timescale 1ns / 1ps

module tb_sipo_fifo;

parameter int DEPTH=8; 
parameter int DATA_WIDTH=8;
parameter int ADDR_WIDTH=$clog2(DEPTH);

logic                        i_clk;
logic                        i_nrst;
logic                        i_clear;
logic                        i_wen;
logic                        i_ren;
logic [DATA_WIDTH-1:0]       i_data_in;
logic [DEPTH*DATA_WIDTH-1:0] o_data_out;
logic                        o_empty;
logic                        o_full;

sipo_fifo # (
    .DEPTH(DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) uut (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_clear(i_clear),
    .i_wen(i_wen),
    .i_ren(i_ren),
    .i_data_in(i_data_in),
    .o_data_out(o_data_out),
    .o_empty(o_empty),
    .o_full(o_full)
);

always #5 i_clk = ~i_clk;

int i;
initial begin
    $dumpfile("tb.vcd");
    $dumpvars;

    i_clk = 0;
    i_nrst = 0;
    i_clear = 0;
    i_wen = 0;
    i_ren = 0;
    i_data_in = 0;
    #10;
    i_nrst = 1;
    #10;
    i_wen = 1;
    while (i<8) begin
        i_data_in = i++;
        #10;
    end
    i_wen = 0;
    i_ren = 1;
    #10;
    i_ren = 0;
    #20;

    $finish;
end

endmodule