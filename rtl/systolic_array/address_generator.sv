module address_generator #(
    parameter int BUF_DEPTH = 64
) (
    input logic i_clk, i_nrst, 
    input logic i_en, i_reg_clear, i_stall_en, // Control signals
    input logic [ADDR_WIDTH-1:0] i_k_size, i_k_num, i_i_size, // Input parameters
    input logic [ADDR_WIDTH-1:0] i_o_x, i_o_y, // Output parameters
    input logic [ADDR_WIDTH-1:0] i_start_addr, // Start address of tile in input buffer
    output logic o_done, o_active,
    output logic [ADDR_WIDTH-1:0] o_read_addr
);
    localparam ADDR_WIDTH = $clog2(BUF_DEPTH);

    logic increment_en;
    logic [ADDR_WIDTH-1:0] k_x, k_y;
    logic [ADDR_WIDTH-1:0] reg_read_addr, reg_k_counter;

    assign increment_en = i_en;

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            k_x <= 0;
            k_y <= 0;
            reg_read_addr <= 0;
            reg_k_counter <= 0;
            o_done <= 0;
            o_active <= 0;
        end else begin
            if ( i_reg_clear) begin
                k_x <= 0;
                k_y <= 0;
                reg_read_addr <= 0;
                reg_k_counter <= 0;
                o_done <= 0;
                o_active <= 0;
            end else if (increment_en && ~o_done) begin
                if (reg_k_counter < i_k_num) begin
                    reg_read_addr <= i_start_addr + (i_o_x + k_x) * i_i_size + (i_o_y + k_y);

                    if (k_y < i_k_size-1) begin
                        k_y <= k_y + 1;
                    end else begin
                        k_y <= 0;
                        if (k_x < i_k_size-1) begin
                            k_x <= k_x + 1;
                        end else begin
                            k_x <= 0;
                        end
                    end

                    reg_k_counter <= reg_k_counter + 1;
                    o_active <= 1;
                end else begin
                    k_x <= 0;
                    k_y <= 0;
                    reg_read_addr <= 0;
                    reg_k_counter <= 0;
                    o_done <= 1;
                    o_active <= 0;
                end
            end
        end
    end

    always_comb begin
        o_read_addr = reg_read_addr;
    end
endmodule