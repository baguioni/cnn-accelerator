// Multiple Input Single Output (MISO) FIFO
module miso_fifo #(
    parameter int DEPTH = 32,  
    parameter int DATA_WIDTH = 8,
    parameter int DATA_LENGTH = 9,
    localparam ADDR_WIDTH = $clog2(DEPTH),
    parameter int INDEX = 0
)(
    input logic i_clk, i_nrst, i_clear, i_write_en, i_pop_en, i_r_pointer_reset,
    input logic [1:0] i_p_mode,
    input logic [DATA_LENGTH-1:0][DATA_WIDTH-1:0] i_data,       
    input logic [DATA_LENGTH-1:0] i_valid,
    output logic [DATA_WIDTH-1:0] o_data,                          
    output logic o_empty, o_full, o_pop_valid       
);
    localparam _8x8 = 2'b00;
    localparam _4x4 = 2'b01;
    localparam _2x2 = 2'b10;

    logic data_out_valid;
    logic [DATA_WIDTH-1:0] data_out;
    logic [ADDR_WIDTH-1:0] w_pointer, r_pointer;
    logic [DATA_WIDTH-1:0] fifo [DEPTH-1:0];

    logic write_en;
    assign write_en = i_write_en & !o_full;

    // Write data
    always @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst) begin
            w_pointer <= 0;
        end else if (i_clear) begin
            w_pointer <= 0;
        end else if (write_en) begin
            for (int i = 0; i < DATA_LENGTH; i = i + 1) begin
                if (i_valid[i] == 1) begin
                    fifo[w_pointer + i] <= i_data[i];
                    w_pointer <= w_pointer + i + 1;
                end 
            end
        end
    end

    // Precision postprocessing

    logic [1:0] ctr;
    logic [DATA_WIDTH-1:0] head, temp;
    assign head = fifo[r_pointer];
    
    // Pop data
    always_ff @ (posedge i_clk or negedge i_nrst) begin
        if (~i_nrst || i_r_pointer_reset) begin
            r_pointer <= 0;
            data_out <= 0;
            temp <= 0;
            data_out_valid <= 0;
            ctr <= 0;
        end else if (i_clear) begin
            r_pointer <= 0;
            data_out <= 0;
            temp <= 0;
            data_out_valid <= 0;
            ctr <= 0;
        end else if (i_pop_en && !o_empty) begin
            r_pointer <= r_pointer + 1;
            case (i_p_mode)
                _8x8: begin
                    data_out <= head;
                    data_out_valid <= 1;
                end
                _4x4: begin
                    if (ctr == 2'b00) begin
                        temp[3:0] <= head[3:0];
                        ctr <= 2'b01;
                        data_out_valid <= 0;
                    end else if (ctr == 2'b01) begin
                        data_out <= {head[3:0], temp[3:0]};
                        temp <= 0;
                        data_out_valid <= 1;
                        ctr <= 0;
                    end
                end
                _2x2: begin
                    if (ctr == 2'b00) begin
                        temp[1:0] <= head[1:0];
                        ctr <= 2'b01;
                        data_out_valid <= 0;
                    end else if (ctr == 2'b01) begin
                        temp[3:2] <= head[1:0];
                        ctr <= 2'b10;
                    end else if (ctr == 2'b10) begin
                        temp[5:4] <= head[1:0];
                        ctr <= 2'b11;
                    end else if (ctr == 2'b11) begin
                        data_out <= {head[1:0], temp[5:0]};
                        data_out_valid <= 1;
                        ctr <= 0;
                    end
                end
                default: begin
                    data_out <= head;
                    data_out_valid <= 0;
                end
            endcase
        end else if (o_empty && i_pop_en) begin
            data_out <= temp;
            data_out_valid <= 1;
        end
    end

    // Status signals
    always_comb begin
        o_full = (w_pointer + 1) == r_pointer;
        o_empty = (w_pointer == r_pointer);
        o_data = data_out;
        o_pop_valid = data_out_valid;
    end
endmodule
