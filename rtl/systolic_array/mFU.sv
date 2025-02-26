module mFU (
    input  logic        clk, nrst,
    input  logic [ 7:0] a, b,
    input  logic [ 1:0] mode,
    output logic [15:0] p
);

    localparam _8x8 = 2'b00;
    localparam _4x4 = 2'b01;
    localparam _2x2 = 2'b10;
    localparam NOOP = 2'b11;

    // Enable signal generaion
    logic [15:0] en;
    always @(*) begin
        case (mode)
            _8x8: en = 16'b1111_1111_1111_1111;
            _4x4: en = 16'b1111_0000_0000_1111;
            _2x2: en = 16'b1001_0000_0000_1001; 
            default: en = 16'b0;
        endcase
    end
    
    // Select signal generation
    logic [31:0] sel;
    always @(*) begin
        case (mode)
            _8x8: sel = 32'b11100100_10100000_01000100_00000000;
            _4x4: sel = 32'b11100100_00000000_00000000_11100100;
            _2x2: sel = 32'b11000011_00000000_00000000_11000011; 
            default: sel = 32'b0;
        endcase
    end

    // Internal signal for partial products
    logic [3:0] p0_ll, p0_hl, p0_lh, p0_hh;
    logic [3:0] p1_ll, p1_hl, p1_lh, p1_hh;
    logic [3:0] p2_ll, p2_hl, p2_lh, p2_hh;
    logic [3:0] p3_ll, p3_hl, p3_lh, p3_hh;

    // Instantiate mBB blocks (16 blocks computing 2bx2b products)
    mBB mbb_0_hh(.en(en[15]), .a(a[7:6]), .b(b[7:6]), .sel(sel[31:30]), .p(p0_hh));
    mBB mbb_0_hl(.en(en[14]), .a(a[7:6]), .b(b[5:4]), .sel(sel[29:28]), .p(p0_hl));
    mBB mbb_0_lh(.en(en[13]), .a(a[5:4]), .b(b[7:6]), .sel(sel[27:26]), .p(p0_lh));
    mBB mbb_0_ll(.en(en[12]), .a(a[5:4]), .b(b[5:4]), .sel(sel[25:24]), .p(p0_ll));

    mBB mbb_1_hh(.en(en[11]), .a(a[7:6]), .b(b[3:2]), .sel(sel[23:22]), .p(p1_hh));
    mBB mbb_1_hl(.en(en[10]), .a(a[7:6]), .b(b[1:0]), .sel(sel[21:20]), .p(p1_hl));
    mBB mbb_1_lh(.en(en[ 9]), .a(a[5:4]), .b(b[3:2]), .sel(sel[19:18]), .p(p1_lh));
    mBB mbb_1_ll(.en(en[ 8]), .a(a[5:4]), .b(b[1:0]), .sel(sel[17:16]), .p(p1_ll));

    mBB mbb_2_hh(.en(en[ 7]), .a(a[3:2]), .b(b[7:6]), .sel(sel[15:14]), .p(p2_hh));
    mBB mbb_2_hl(.en(en[ 6]), .a(a[3:2]), .b(b[5:4]), .sel(sel[13:12]), .p(p2_hl));
    mBB mbb_2_lh(.en(en[ 5]), .a(a[1:0]), .b(b[7:6]), .sel(sel[11:10]), .p(p2_lh));
    mBB mbb_2_ll(.en(en[ 4]), .a(a[1:0]), .b(b[5:4]), .sel(sel[ 9: 8]), .p(p2_ll));

    mBB mbb_3_hh(.en(en[ 3]), .a(a[3:2]), .b(b[3:2]), .sel(sel[ 7: 6]), .p(p3_hh));
    mBB mbb_3_hl(.en(en[ 2]), .a(a[3:2]), .b(b[1:0]), .sel(sel[ 5: 4]), .p(p3_hl));
    mBB mbb_3_lh(.en(en[ 1]), .a(a[1:0]), .b(b[3:2]), .sel(sel[ 3: 2]), .p(p3_lh));
    mBB mbb_3_ll(.en(en[ 0]), .a(a[1:0]), .b(b[1:0]), .sel(sel[ 1: 0]), .p(p3_ll));

    // Partial product accumulation. (4 blocks computing 4bx4b products)
    logic [7:0] p0, p1, p2, p3;
    logic p1_lh_ex, p2_hl_ex;
    logic p3_hl_ex, p3_lh_ex;
    assign p1_lh_ex = (mode==_8x8)? 0 : p1_lh[3];
    assign p2_hl_ex = (mode==_8x8)? 0 : p2_hl[3];
    assign p3_hl_ex = (mode==_8x8)? 0 : p3_hl[3];
    assign p3_lh_ex = (mode==_8x8)? 0 : p3_lh[3];

    assign p0 = {p0_hh,p0_ll} + { { {2{p0_hl[3]}} , p0_hl } + { {2{p0_lh[3]}} , p0_lh } , 2'b00};
    assign p1 = {p1_hh,p1_ll} + { { {2{p1_hl[3]}} , p1_hl } + { {2{p1_lh_ex}} , p1_lh } , 2'b00};
    assign p2 = {p2_hh,p2_ll} + { { {2{p2_hl_ex}} , p2_hl } + { {2{p2_lh[3]}} , p2_lh } , 2'b00};
    assign p3 = {p3_hh,p3_ll} + { { {2{p3_hl_ex}} , p3_hl } + { {2{p3_lh_ex}} , p3_lh } , 2'b00};

    always @(*) begin
        if (!nrst) begin
            p = 16'h0;
        end else begin
            case (mode)
                _8x8:    p = { p0, p3 } +  { { {4{p1[7]}} , p1 } + { {4{p2[7]}} , p2 } , 4'b0000 };
                _4x4:    p = {{8{p0[7]}},p0} + {{8{p3[7]}},p3};
                _2x2:    p = {{12{p0_hh[3]}},p0_hh} + {{12{p0_ll[3]}},p0_ll} + {{12{p3_hh[3]}},p3_hh} + {{12{p3_ll[3]}},p3_ll};
                default: p = 16'h0;
            endcase
        end
    end

endmodule
