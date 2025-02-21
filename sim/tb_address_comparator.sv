`timescale 1ns / 1ps

module address_comparator_tb;
    parameter SRAM_WIDTH = 64;
    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 8;
    parameter PEEK_WIDTH = 4;
    
    logic i_en;
    logic [SRAM_WIDTH-1:0] i_data;
    logic [ADDR_WIDTH-1:0] i_addr;
    logic [PEEK_WIDTH-1:0][ADDR_WIDTH-1:0] i_peek_addr;
    logic [PEEK_WIDTH-1:0] i_peek_valid;
    
    logic [PEEK_WIDTH-1:0] o_addr_hit;
    logic [PEEK_WIDTH-1:0][DATA_WIDTH-1:0] o_data_hit;
    
    address_comparator #(
        .SRAM_WIDTH(SRAM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .PEEK_WIDTH(PEEK_WIDTH)
    ) uut (
        .i_en(i_en),
        .i_data(i_data),
        .i_addr(i_addr),
        .i_peek_addr(i_peek_addr),
        .i_peek_valid(i_peek_valid),
        .o_addr_hit(o_addr_hit),
        .o_data_hit(o_data_hit)
    );
    
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
        
        i_en = 1;
        
        // Initialize peek addresses
        i_peek_addr[0] = 0;
        i_peek_addr[1] = 1;
        i_peek_addr[2] = 2;
        i_peek_addr[3] = 3;
        
        i_peek_valid = 4'b1111; // All valid
        
        i_addr = 0;
        i_data = {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0}; // Example SRAM data
        #10;
        // Initialize peek addresses
        i_peek_addr[0] = 6;
        i_peek_addr[1] = 7;
        i_peek_addr[2] = 8;
        i_peek_addr[3] = 13;
        i_peek_valid = 4'b1111; // All valid


        i_addr = 1;
        i_data = {8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9, 8'd8}; // Example SRAM data
        #10;
            
            $display("i_addr = %d, o_addr_hit = %b, o_data_hit = %p", i_addr, o_addr_hit, o_data_hit);
        
        
        $finish;
    end
endmodule
