`timescale 1ns/1ps

module pe #(
    parameter int DATA_WIDTH = 8
) (
    input logic i_clk, i_nrst, 

    input logic [1:0] i_mode,

    // Data Inputs 
    input logic [DATA_WIDTH-1:0] i_ifmap, i_weight,
    input logic [DATA_WIDTH*2-1:0] i_psum,

    // Control Inputs

    input logic i_reg_clear, // Clear register
    input logic i_pe_en,  // Enable PE to perform multiply-and-accumulate

    input logic i_relu_en,

    // Enable one cycle after last computation to 
    // output partial sum to the next PE
    // Performs a shift operation to the left
    input logic i_psum_out_en,

    // Data Outputs
    output logic [DATA_WIDTH-1:0] o_ifmap, o_weight,
    output logic [DATA_WIDTH*2-1:0] o_ofmap
);

    logic [DATA_WIDTH-1:0] reg_ifmap, reg_weight;
    logic [DATA_WIDTH*2-1:0] reg_psum, o_multiplier, relu_out;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_ifmap <= 0;
            reg_weight <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_ifmap <= 0;
                reg_weight <= 0;
            end else if (i_pe_en) begin
                reg_ifmap <= i_ifmap;
                reg_weight <= i_weight;
            end
        end
    end

    mFU mfu (
        .clk(i_clk),
        .nrst(i_nrst),
        .a(i_ifmap),
        .b(i_weight),
        .mode(i_mode),
        .p(o_multiplier)
    );

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if(~i_nrst) begin
            reg_psum <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_psum <= 0;
            end else if(i_pe_en) begin
                reg_psum <= reg_psum + o_multiplier;
            end else if(i_psum_out_en) begin
                reg_psum <= i_psum;
            end
        end
    end

    always_comb begin
        if (reg_psum < 0) begin
            relu_out = 0;
        end else if (reg_psum >= 0 && reg_psum <= 6) begin
            relu_out = reg_psum;
        end else begin
            relu_out = 6;
        end
    end

    always_comb begin
        o_ifmap = reg_ifmap;
        o_weight = reg_weight;
        o_ofmap = (!i_relu_en)? reg_psum : relu_out;
    end

endmodule