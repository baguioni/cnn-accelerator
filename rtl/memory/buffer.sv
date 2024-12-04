module buffer #(
    parameter int DEPTH = 64,
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
    input logic i_clk, i_write_en, i_read_en,
    input logic [DATA_WIDTH-1:0] i_data_in,
    input logic [ADDR_WIDTH-1:0] i_write_addr, i_read_addr
    output logic [DATA_WIDTH-1:0] o_data_out
);
    logic [DATA_WIDTH-1:0] buffer [DEPTH-1:0];
    logic [DATA_WIDTH-1:0] reg_data_out;

    initial begin
        $monitor("[%0t] [BUFFER] writeEn=%0b dataIn=0x%0h readEn=%0b dataOut=0x%0h",
            $time, i_write_en, i_data_in, i_read_en, o_data_out);
    end

    // Read data
    always_ff @(posedge clk) begin
        if (i_read_en) begin
            reg_data_out <= buffer[i_read_addr];
        end
    end

    assign o_data_out = reg_data_out;

    // Write data
    always_ff @(posedge i_clk) begin
        if (i_write_en) begin
            buffer[i_write_addr] <= dataIn;
        end
    end

endmodule
