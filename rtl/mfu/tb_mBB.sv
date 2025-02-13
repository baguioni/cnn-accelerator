`timescale 1ns/1ps

module tb_mBB;
logic       clk,en;
logic [1:0] a,b,sel;
logic [3:0] p;

mBB uut (
    .en(en),
    .a(a),
    .b(b),
    .sel(sel),
    .p(p)
);

localparam CLK = 10;
always #(CLK/2) clk=~clk;

initial begin
    $dumpfile("tb.vcd");
    $dumpvars();

    clk <= 0;
    en  <= 0;
    a   <= 0;
    b   <= 0;
    sel <= 0;

    #(CLK);

    for (integer s=0; s<4; s=s+1) begin
        for (integer i=0; i<16; i=i+1) begin
            en  <= 1;
            a   <= i[3:2];
            b   <= i[1:0];
            sel <= s;
            #(CLK);
            en  <= 0;
            #(CLK);
        end
    end

    $finish;
end

endmodule