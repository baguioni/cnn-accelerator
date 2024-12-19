module input_router #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 6,
    parameter int HEIGHT = 4,
) (
    input logic i_clk, i_nrst,
    // ====== Control signals ====== 
    input logic i_en, i_reg_clear,
    input logic [ADDR_WIDTH-1:0] i_k_size, i_k_num, i_i_size, i_start_addr,

    // ====== Tile Reader signals ====== 
    input logic i_valid_addr,
    input logic [DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_addr

    // ====== Systolic Array signals ====== 
    output logic [0:HEIGHT-1][DATA_WIDTH-1:0] o_ifmap, 

    // ====== Status signals ====== 
    output logic o_active, o_done
);
    // Need to generate i_o_x and i_o_y signals for each router
    logic [0:(HEIGHT*HEIGHT)-1][ADDR_WIDTH-1:0]  o_x, o_y;
    logic [ADDR_WIDTH-1:0] o_size;

    for (int i = 0; i < HEIGHT; i++) begin
        for (int y = 0, y < HEIGHT, y++) begin
            o_x[i] = i;
            o_y[i] = y;
        end
    end

    genvar ii;
    generate
        for (ii=0; ii < HEIGHT; ii++) begin : y_ios
            row_router #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) row_router_inst (
                .i_clk(i_clk),
                .i_nrst(i_nrst),
                .i_en(i_en),
                .i_reg_clear(i_reg_clear),
                .i_stall_en(),
                .i_k_size(i_k_size),
                .i_k_num(i_k_num),
                .i_i_size(i_i_size),
                .i_o_x(o_x[ii]),
                .i_o_y(o_y[ii]),
                .i_start_addr(i_start_addr),
                .o_ag_done(),
                .i_valid_addr(i_valid_addr),
                .i_data_in(i_data_in),
                .i_addr(i_addr),
                .i_pop_en(),
                .i_zero_padding_en(),
                .i_pad_count(),
                .o_data_out(o_ifmap[ii])
            )
        end
    endgenerate
endmodule