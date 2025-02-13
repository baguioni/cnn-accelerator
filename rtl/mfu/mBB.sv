`timescale 1ns/1ps

module HA (input logic a, b, output logic s, c );
    assign s = a ^ b;
    assign c = a & b;
endmodule

module mBB (
    input  logic       en,
    input  logic [1:0] a, b, sel,
    output logic [3:0] p
);
    // Mode Selection (U - unsigned, S - signed)
    localparam UxU = 2'b00;
    localparam UxS = 2'b01;
    localparam SxU = 2'b10;
    localparam SxS = 2'b11;

    logic [1:0] ai, bi;
    logic [3:0] pi;

    // Input reassignment to save logic for UxS and SxU
    assign ai = (!en)? 0 : (sel==UxS)? b : a;
    assign bi = (!en)? 0 : (sel==UxS)? a : b;

    // Partial products
    logic [1:0] pp0, pp1;
    
    assign pp0 = { (ai[1] & bi[0]), (ai[0] & bi[0]) };
    assign pp1 = { (ai[1] & bi[1]), (ai[0] & bi[1]) };
    
    // p0
    assign pi[0] = pp0[0];

    // p1
    logic HA_p1_co;
    HA HA_p1(
        .a((sel==0)? pp0[1] : ~pp0[1]),
        .b((sel==0)? pp1[0] : ~pp1[0]),
        .c(HA_p1_co),
        .s(pi[1]));

    // p2
    logic HA_p2_1_co, HA_p2_1_s;
    HA HA_p2_1(
        .a(1'b1),
        .b(pp1[1]),
        .c(HA_p2_1_co),
        .s(HA_p2_1_s));
    logic HA_p2_0_a, p3_0;
    assign HA_p2_0_a = (sel==0)? pp1[1] : HA_p2_1_s;
    HA HA_p2_0(
        .a(HA_p2_0_a),
        .b(HA_p1_co),
        .c(p3_0),
        .s(pi[2]));

    // p3
    assign pi[3] = (sel==0)? p3_0: ~(HA_p2_1_co | p3_0);

    always @(*) begin
        if (en) begin
            case (sel)
                UxU, SxS: p <= pi;
                UxS, SxU: p <= (~bi[1])? pi : 
                        {(pi[3] ^ ai[1]) ^ (pi[2] & ai[0]), // p3
                         (pi[2] ^ ai[0]) ,  pi[1:0]};       // p2 p1 p0
            endcase
        end else begin
            p <= 4'b0; 
        end
    end
endmodule