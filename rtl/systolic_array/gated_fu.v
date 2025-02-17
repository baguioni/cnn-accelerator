// TODO:
// implement signed mult

module gated_fu (
    input  [ 7:0] a, b,
    input  [ 1:0] mode,
    output [15:0] p
);
    /**** **** **** **** ****  BLOCK 0  **** **** **** **** ****/

    // wire [1:0] s0_ll, s0_hl, s0_lh, s0_hh;
    wire [3:0] p0_ll, p0_hl, p0_lh, p0_hh;

    mBB mBB0_ll(.a((!blk_en[0])? 2'b0 : a[1:0]), .b((!blk_en[0])? 2'b0 : b[1:0]), .p(p0_ll), .sel(2'b00));
    mBB mBB0_hl(.a((!blk_en[1])? 2'b0 : a[3:2]), .b((!blk_en[1])? 2'b0 : b[1:0]), .p(p0_hl), .sel(2'b00));
    mBB mBB0_lh(.a((!blk_en[2])? 2'b0 : a[1:0]), .b((!blk_en[2])? 2'b0 : b[3:2]), .p(p0_lh), .sel(2'b00));
    mBB mBB0_hh(.a((!blk_en[3])? 2'b0 : a[3:2]), .b((!blk_en[3])? 2'b0 : b[3:2]), .p(p0_hh), .sel(2'b00));

    /**** **** **** **** ****  BLOCK 1  **** **** **** **** ****/

    // wire [1:0] s1_ll, s1_hl, s1_lh, s1_hh;
    wire [3:0] p1_ll, p1_hl, p1_lh, p1_hh;

    mBB mBB1_ll(.a((!blk_en[4])? 2'b0 : a[5:4]), .b((!blk_en[4])? 2'b0 : b[1:0]), .p(p1_ll), .sel(2'b00));
    mBB mBB1_hl(.a((!blk_en[5])? 2'b0 : a[7:6]), .b((!blk_en[5])? 2'b0 : b[1:0]), .p(p1_hl), .sel(2'b00));
    mBB mBB1_lh(.a((!blk_en[6])? 2'b0 : a[5:4]), .b((!blk_en[6])? 2'b0 : b[3:2]), .p(p1_lh), .sel(2'b00));
    mBB mBB1_hh(.a((!blk_en[7])? 2'b0 : a[7:6]), .b((!blk_en[7])? 2'b0 : b[3:2]), .p(p1_hh), .sel(2'b00));
    
    /**** **** **** **** ****  BLOCK 2  **** **** **** **** ****/

    // wire [1:0] s2_ll, s2_hl, s2_lh, s2_hh;
    wire [3:0] p2_ll, p2_hl, p2_lh, p2_hh;

    mBB mBB2_ll(.a((!blk_en[ 8])? 2'b0 : a[1:0]), .b((!blk_en[ 8])? 2'b0 : b[5:4]), .p(p2_ll), .sel(2'b00));
    mBB mBB2_hl(.a((!blk_en[ 9])? 2'b0 : a[3:2]), .b((!blk_en[ 9])? 2'b0 : b[5:4]), .p(p2_hl), .sel(2'b00));
    mBB mBB2_lh(.a((!blk_en[10])? 2'b0 : a[1:0]), .b((!blk_en[10])? 2'b0 : b[7:6]), .p(p2_lh), .sel(2'b00));
    mBB mBB2_hh(.a((!blk_en[11])? 2'b0 : a[3:2]), .b((!blk_en[11])? 2'b0 : b[7:6]), .p(p2_hh), .sel(2'b00));

    /**** **** **** **** ****  BLOCK 3  **** **** **** **** ****/

    // wire [1:0] s3_ll, s3_hl, s3_lh, s3_hh;
    wire [3:0] p3_ll, p3_hl, p3_lh, p3_hh;

    mBB mBB3_ll(.a((!blk_en[12])? 2'b0 : a[5:4]), .b((!blk_en[12])? 2'b0 : b[5:4]), .p(p3_ll), .sel(2'b00));
    mBB mBB3_hl(.a((!blk_en[13])? 2'b0 : a[7:6]), .b((!blk_en[13])? 2'b0 : b[5:4]), .p(p3_hl), .sel(2'b00));
    mBB mBB3_lh(.a((!blk_en[14])? 2'b0 : a[5:4]), .b((!blk_en[14])? 2'b0 : b[7:6]), .p(p3_lh), .sel(2'b00));
    mBB mBB3_hh(.a((!blk_en[15])? 2'b0 : a[7:6]), .b((!blk_en[15])? 2'b0 : b[7:6]), .p(p3_hh), .sel(2'b00));

    localparam _8x8 = 2'b00;
    localparam _4x4 = 2'b01;
    localparam _2x2 = 2'b10;

    // GATING CONTROL

    reg [15:0] blk_en;

    always @(*) begin
        case (mode)
            _2x2:    blk_en = 16'b1001000000001001;
            _4x4:    blk_en = 16'b1111000000001111;
            _8x8:    blk_en = 16'b1111111111111111;
            default: blk_en = 16'b0000000000000000;
        endcase
    end

    // OUTPUT CONTROL

    reg [15:0] pi;

    always @(*) begin
        case (mode)
            _2x2: begin
                pi <= {p3_hh,p3_ll,p0_hh,p0_ll};
            end
            _4x4: begin
                pi <= {
                    {p3_hh,p3_ll}+((p3_hl + p3_lh)<<2),
                    {p0_hh,p0_ll}+((p0_hl + p0_lh)<<2)};
            end
            _8x8: begin
                pi <= {
                    {{p3_hh,p3_ll}+((p3_hl + p3_lh)<<2) , {p0_hh,p0_ll}+((p0_hl + p0_lh)<<2)} + 
                    (({p2_hh,p2_ll}+((p2_hl + p2_lh)<<2) + {p1_hh,p1_ll}+((p1_hl + p1_lh)<<2))<<4)};
            end
            default: begin
                pi <= 0;
            end
        endcase
    end

    assign p = pi;

endmodule