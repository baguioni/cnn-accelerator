module sram #(
    parameter int DEPTH = 64,
    parameter int DATA_WIDTH = 8,
    parameter int WRITE_WIDTH = 4,
    parameter int READ_WIDTH = 2,
    parameter int ADDR_WIDTH = $clog2(DEPTH * WRITE_WIDTH)
) (
    input logic i_clk, i_nrst, i_write_en, i_read_en,
    input logic [0:WRITE_WIDTH-1][DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr,
    input logic [0:READ_WIDTH-1][ADDR_WIDTH-1:0] i_read_addr, 
    output logic [0:READ_WIDTH-1][DATA_WIDTH-1:0] o_data_out
);
    logic [DATA_WIDTH-1:0] sram [0:(DEPTH * WRITE_WIDTH)-1];

    // Write takes precedence over read
    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            for (int i = 0; i < DEPTH * WRITE_WIDTH; i++) begin
                sram[i] <= '0;
            end
        end else begin
            if (i_write_en) begin
                for (int i = 0; i < WRITE_WIDTH; i++) begin
                    sram[i_write_addr + i] <= i_data_in[i];
                end
            end else if (i_read_en) begin
                for (int i = 0; i < READ_WIDTH; i++) begin
                    o_data_out[i] <= sram[i_read_addr[i]];
                end
            end
        end
    end
endmodule
