`timescale 1ns/1ps

module tb_mFU;

reg                clk, nrst;
reg  signed [ 7:0] a, b;
reg         [ 1:0] mode;
wire        [15:0] p;

wire signed [ 3:0] ah, al, bh, bl;
wire signed [ 1:0] ahh, ahl, alh, all;
wire signed [ 1:0] bhh, bhl, blh, bll;

wire signed [15:0] ps;
wire signed [ 7:0] ph,pl;
wire signed [ 3:0] phh,phl,plh,pll;

assign ah = a[7:4];
assign al = a[3:0];
assign bh = b[7:4];
assign bl = b[3:0];

assign ahh = a[7:6];
assign ahl = a[5:4];
assign alh = a[3:2];
assign all = a[1:0];

assign bhh = b[7:6];
assign bhl = b[5:4];
assign blh = b[3:2];
assign bll = b[1:0];

assign ps = p;

assign ph = p[15:8];
assign pl = p[ 7:0];

assign phh = ph[7:4];
assign phl = ph[3:0];
assign plh = pl[7:4];
assign pll = pl[3:0];

mFU uut (
    .clk(clk),
    .nrst(nrst),
    .a(a),
    .b(b),
    .mode(mode),
    .p(p)
);

localparam CLK = 10;
always #(CLK/2) clk=~clk;

integer i;
initial begin
    $dumpfile("tb.vcd");
    $dumpvars();

    clk  = 0;
    nrst = 0;
    mode = 0;
    a    = 0;
    b    = 0;

    #(CLK);
    nrst = 1;

    #(CLK);

    for (i=1; i<4; i=i+1) begin
        mode = i;
        a    = $random;
        b    = $random;
        #(CLK);
        display(mode);
    end

    mode = 0;
    a    = 0;
    b    = 0;
    #(CLK*5);

    $finish(2);
end

task display;
    input [1:0] mode;
    begin
        $display("a=%b, b=%b p=%b", a, b, p);
        case (mode)
            2'b01:  $display("%d x %d = %d", a, b, ps);
            2'b10: begin
                    $display("%d x %d = %d", ah, bh, ph);
                    $display("%d x %d = %d", al, bl, pl);
            end
            2'b11: begin
                    $display("%d x %d = %d", ahh, bhh, phh);
                    $display("%d x %d = %d", ahl, bhl, phl);
                    $display("%d x %d = %d", alh, blh, plh);
                    $display("%d x %d = %d", all, bll, pll);
            end
            2'b00:  $display("NOOP");
        endcase
    end
endtask

endmodule