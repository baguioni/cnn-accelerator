module spad # (
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 64
) (
    input logic i_clk, i_nrst, i_write_en, i_read_en,
    input logic [DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr, i_read_addr,
    output logic [DATA_WIDTH-1:0] o_data_out,
    output logic o_data_out_valid
);
    logic [DATA_WIDTH-1:0] buffer [(2**ADDR_WIDTH)-1:0];

    // initial begin
    //     $monitor("[%0t] [BUFFER] writeEn=%0b dataIn=0x%0h readEn=%0b dataOut=0x%0h",
    //         $time, i_write_en, i_data_in, i_read_en, o_data_out);
    // end

    // Read data
    always_ff @(posedge i_clk) begin
        if (i_read_en) begin
            o_data_out <= buffer[i_read_addr];
        end
    end

    always_ff @(posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            o_data_out_valid <= 0;
        end else begin
            if (i_read_en) begin
                o_data_out_valid <= 1;
            end else begin
                o_data_out_valid <= 0;
            end
        end
    end

    // Write data
    always_ff @(posedge i_clk) begin
        if (i_write_en) begin
            buffer[i_write_addr] <= i_data_in;
        end
    end

endmodule