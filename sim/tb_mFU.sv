`timescale 1ns/1ps

module tb_mFU;

logic               clk, nrst;
logic signed [ 7:0] a, b;
logic        [ 1:0] mode;
logic signed [15:0] p;

mFU uut (
    .clk(clk),
    .nrst(nrst),
    .a(a),
    .b(b),
    .mode(mode),
    .p(p)
);

always #5 clk=~clk;

integer ip_file, op_file;
initial begin
    $dumpfile("tb.vcd");
    $dumpvars();

    clk  = 0;
    nrst = 0;
    mode = 0;
    a    = 0;
    b    = 0;
    #10;

    #5;
    nrst = 1;
    
    ip_file = $fopen(".././scripts/input.txt" ,"r");
    if (ip_file)  $display("Input file opened: %0d",ip_file);
    else      $display("Input file NOT opened: %0d",ip_file);

    op_file = $fopen(".././scripts/test.txt","w");
    if (op_file) $display("Output file opened: %0d",op_file);
    else     $display("Output file NOT opened: %0d",op_file);

    #10;

    while ($fscanf(ip_file, "%d,%d,%d\n", mode,a,b) == 3) begin
        #10;
        $fdisplay(op_file, "%0d", p);
    end

    #50;
    $display("Test complete");
    $fclose(ip_file);
    $fclose(op_file);
    $finish;
end

endmodule