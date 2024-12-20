module router_controller #(
    parameter int SA_HEIGHT = 4,
    parameter int KERNEL_SIZE = 3,
    parameter int ADDR_WIDTH = 6
) (
    input logic i_clk, i_nrst, i_en, i_reg_clear, i_compute_done,
    input logic [ADDR_WIDTH-1:0] i_start_addr, i_o_size,
    output logic [SA_BITS-1:0] o_row_number,
    output logic [ADDR_WIDTH-1:0] o_o_x, o_o_y,
    output logic o_done, o_ag_en
);
    localparam SA_BITS = $clog2(SA_HEIGHT);

// Basically a counter of the output feature map
    logic [ADDR_WIDTH-1:0] reg_o_x, reg_o_y;
    logic [SA_BITS-1:0] row_counter;
    logic increment_en, done, row_full, stall;

    assign increment_en = i_en && ~stall && ~done;

    // Output feature map counter
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            reg_o_x <= 0;
            reg_o_y <= 0;
            row_counter <= 0;
            done <= 0;
        end else begin
            if (i_reg_clear) begin
                reg_o_x <= 0;
                reg_o_y <= 0;
                row_counter <= 0;
                done <= 0;
            end else if (increment_en) begin
                row_counter <= row_counter + 1;
                if (reg_o_y < i_o_size-1) begin
                    reg_o_y <= reg_o_y + 1;
                    done <= 0;
                end else begin
                    reg_o_y <= 0;
                    if (reg_o_x < i_o_size-1) begin
                        reg_o_x <= reg_o_x + 1;
                        done <= 0;
                    end else begin
                        reg_o_x <= 0;
                        done <= 1;
                    end
                end
            end
        end
    end

    // reg_clear -> enable

    // Systolic array row counter
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            row_counter <= 0;
            stall <= 0;
            o_ag_en <= 0;
        end else begin
            if (i_reg_clear || i_compute_done) begin
                row_counter <= 0;
                stall <= 0;
                o_ag_en <= 0;
            end else if (increment_en) begin
                if (row_counter == SA_HEIGHT-1) begin
                    stall <= 1;
                    o_ag_en <= 0;
                end else begin
                    row_counter <= row_counter + 1;
                    o_ag_en <= 1;
                end
            end
        end
    end

    always_comb begin  
        o_o_x = reg_o_x;
        o_o_y = reg_o_y;
        o_done = done;
        o_row_number = row_counter;
    end
endmodule
