module address_generator #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 8,
    parameter int DATA_LENGTH = 9,
    parameter int KERNEL_SIZE = 3
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear,
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, i_i_size, i_start_addr,
    output logic o_valid,
    output logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] o_addr
);
    logic [0:DATA_LENGTH-1][DATA_WIDTH-1:0] addr;
    genvar x, y;
    generate
        for (x = 0; x < KERNEL_SIZE; x = x + 1) begin : gen_x
            for (y = 0; y < KERNEL_SIZE; y = y + 1) begin : gen_y
                localparam int addr_idx = x * KERNEL_SIZE + y;
                always_comb begin
                    addr[addr_idx] = i_start_addr + ((i_o_x + x) * i_i_size + (i_o_y + y));
                end
            end
        end
    endgenerate

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst ) begin
            o_addr <= '0;
        end else begin
            if (i_reg_clear) begin
                o_addr <= '0;
            end else if (i_en) begin
                o_addr <= addr;
            end
        end
    end

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            o_valid <= 0;
        end else begin
            if (i_en) begin
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end

endmodule
