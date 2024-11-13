module HA (input  a, b, output s, c );
    assign s = a ^ b;
    assign c = a & b;
endmodule

module mBB (
    input      [1:0] a, b, sel,
    output reg [3:0] p
);
    // sel[1] = 1 if a is signed else 0
    // sel[0] = 1 if b is signed else 0

    wire [1:0] ai, bi;
    wire [3:0] pi;

    localparam UU = 2'b00; // unsigned x unsigned
    localparam US = 2'b01; // unsigned x signed
    localparam SU = 2'b10; // signed x unsigned
    localparam SS = 2'b11; // signed x signed

    assign ai = (sel==US)? b : a;
    assign bi = (sel==US)? a : b;

    wire [1:0] pp0, pp1;
    // partial product
    assign pp0 = { (ai[1] & bi[0]), (ai[0] & bi[0]) };
    assign pp1 = { (ai[1] & bi[1]), (ai[0] & bi[1]) };
    // p0
    assign pi[0] = pp0[0];
    // p1
    wire HA_p1_co;
    HA HA_p1(
        .a((sel==0)? pp0[1] : ~pp0[1]),
        .b((sel==0)? pp1[0] : ~pp1[0]),
        .c(HA_p1_co),
        .s(pi[1]));
    // p2
    wire HA_p2_1_co, HA_p2_1_s;
    HA HA_p2_1(
        .a(1'b1),
        .b(pp1[1]),
        .c(HA_p2_1_co),
        .s(HA_p2_1_s));
    wire HA_p2_0_a, p3_0;
    assign HA_p2_0_a = (sel==0)? pp1[1] : HA_p2_1_s;
    HA HA_p2_0(
        .a(HA_p2_0_a),
        .b(HA_p1_co),
        .c(p3_0),
        .s(pi[2]));
    // p3
    assign pi[3] = (sel==0)? p3_0: ~(HA_p2_1_co | p3_0);

    always @(*) begin
        case (sel)
            UU, SS: p <= pi;
            US, SU: p <= (~bi[1])? pi : 
                    {(pi[3] ^ ai[1]) ^ (pi[2] & ai[0]), // p3
                     (pi[2] ^ ai[0]), pi[1:0]};         // p2 p1 p0
        endcase
    end
endmodule