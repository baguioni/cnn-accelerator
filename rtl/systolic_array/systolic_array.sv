module systolic_array #(
    parameter DATA_WIDTH = 8,
    parameter WIDTH = 2,
    parameter HEIGHT = 2
) (
    input logic i_clk, i_nrst, i_reg_clear, i_pe_en, i_psum_out_en,
    input logic [1:0] i_mode,
    input logic [0:HEIGHT-1][DATA_WIDTH-1:0] i_ifmap, 
    input logic [0:WIDTH-1][DATA_WIDTH-1:0] i_weight,
    output logic [0:HEIGHT-1][DATA_WIDTH*2-1:0] o_ofmap
);
    logic [0:HEIGHT-1][0:WIDTH][DATA_WIDTH-1:0] mat_A;
    logic [0:HEIGHT][0:WIDTH-1][DATA_WIDTH-1:0] mat_B;
    logic [0:HEIGHT-1][0:WIDTH][DATA_WIDTH*2-1:0] mat_C;

    // Mapping of ifmap
    genvar jj;
    generate
        for (jj=0; jj < HEIGHT; jj++) begin : y_ios
            assign mat_A[jj][0] = i_ifmap[jj]; 
            assign o_ofmap[jj] = mat_C[jj][0];
        end
    endgenerate

    // Mapping of weight
    genvar ii;
    generate
        for (ii=0; ii < WIDTH; ii++) begin : x_ios
            assign mat_B[0][ii] = i_weight[ii];
        end
    endgenerate

    // Instantiate the PE systolic array
    genvar i, j;
    generate
        for (j=0; j < HEIGHT; j++) begin : y_axis
            for (i=0; i < WIDTH; i++) begin : x_axis
                pe #(
                    .DATA_WIDTH(DATA_WIDTH)
                ) pe_inst (
                    .i_clk(i_clk),
                    .i_nrst(i_nrst),
                    .i_mode(i_mode),
                    .i_ifmap(mat_A[j][i]),
                    .i_weight(mat_B[j][i]),
                    // .i_psum(mat_C[j][i+1]),
                    .i_reg_clear(i_reg_clear),
                    .i_pe_en(i_pe_en),
                    .i_psum_out_en(i_psum_out_en),
                    .o_ifmap(mat_A[j][i+1]),
                    .o_weight(mat_B[j+1][i]),
                    .o_ofmap(mat_C[j][i])
                );
            end
        end
    endgenerate
endmodule