`timescale 1ns/1ps

module miso_fifo_tb;
    parameter int DEPTH = 32;
    parameter int DATA_WIDTH = 8;
    parameter int DATA_LENGTH = 8;
    
    logic i_clk, i_nrst, i_clear, i_write_en, i_pop_en, i_r_pointer_reset;
    logic [1:0] i_p_mode;
    logic [DATA_LENGTH-1:0][DATA_WIDTH-1:0] i_data;
    logic [DATA_LENGTH-1:0] i_valid;
    logic [DATA_WIDTH-1:0] o_data;
    logic o_empty, o_full, o_pop_valid;
    
    // Instantiate the FIFO
    miso_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_LENGTH(DATA_LENGTH)
    ) dut (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_clear),
        .i_write_en(i_write_en),
        .i_pop_en(i_pop_en),
        .i_r_pointer_reset(i_r_pointer_reset),
        .i_p_mode(i_p_mode),
        .i_data(i_data),
        .i_valid(i_valid),
        .o_data(o_data),
        .o_empty(o_empty),
        .o_full(o_full),
        .o_pop_valid(o_pop_valid)
    );
    
    // Clock generation
    always #5 i_clk = ~i_clk;
    
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
        
        i_clk = 0;
        i_nrst = 0;
        i_clear = 0;
        i_write_en = 0;
        i_pop_en = 0;
        i_r_pointer_reset = 0;
        i_p_mode = 2'b00; // _4x4 mode
        i_data = 0;
        i_valid = 0;
        
        // Reset sequence
        #10 i_nrst = 1;
        
        // 8-bit mode
        #10; 
        i_p_mode = 2'b00;
        #10 i_write_en = 1;
            i_data[0] = 8'h11; i_valid[0] = 1;
            i_data[1] = 8'h22; i_valid[1] = 1;
        #10 i_write_en = 0;
        i_pop_en = 1;
        #20;
        i_pop_en = 0;
        i_clear = 1;
        #10 i_clear = 0;
        i_p_mode = 2'b01;
        // Write 4 data values
        #10 i_write_en = 1;
            i_data[0] = 8'h01; i_valid[0] = 1;
            i_data[1] = 8'h02; i_valid[1] = 1;
            i_data[2] = 8'h03; i_valid[2] = 1;
            i_data[3] = 8'h04; i_valid[3] = 1;
            i_data[4] = 8'h05; i_valid[4] = 1;
        #10 i_write_en = 0;
        // #10 i_write_en = 1;
        //     i_data[0] = 8'h06; i_valid[0] = 1;
        //     i_data[1] = 8'h00; i_valid[1] = 0;
        //     i_data[2] = 8'h00; i_valid[2] = 0;
        //     i_data[3] = 8'h00; i_valid[3] = 0;
        //     i_data[4] = 8'h00; i_valid[4] = 0;
        // #10 i_write_en = 0;
        i_pop_en = 1;
        #30 i_pop_en = 0;
        i_clear = 1;
        #10 i_clear = 0;
        i_p_mode = 2'b10;
        #10 i_write_en = 1;
            i_data[0] = 8'h01; i_valid[0] = 1;
            i_data[1] = 8'h01; i_valid[1] = 1;
            i_data[2] = 8'h01; i_valid[2] = 1;
            i_data[3] = 8'h01; i_valid[3] = 1;
            i_data[4] = 8'h01; i_valid[4] = 1;
            i_data[5] = 8'h01; i_valid[5] = 1;
            i_data[6] = 8'h01; i_valid[6] = 1;
        #10 i_write_en = 0;
        i_pop_en = 1;
        #30 i_pop_en = 0;

        
        #100 $finish;
    end
    
    always @(posedge i_clk) begin
        if (o_pop_valid) begin
            $display("Time %t: Popped Data = %h", $time, o_data);
        end
    end
endmodule
