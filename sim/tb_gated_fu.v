`timescale 1ns / 1ps

module gated_fu_tb;
    
    reg [7:0] a, b;
    reg [1:0] mode;
    wire [15:0] p;
    
    // Instantiate the DUT (Device Under Test)
    gated_fu uut (
        .a(a),
        .b(b),
        .mode(mode),
        .p(p)
    );
    
    initial begin
        // Enable waveform dumping
        $dumpfile("tb.vcd");
        $dumpvars;
        
        // // Test Case 1: 8x8 unsigned multiplication
        // a = 8'b00001111; // 15
        // b = 8'b00000011; // 3
        // mode = 2'b00;
        // #10;
        
        // Test Case 2: 4x4 multiplication
        a = 8'h11; // 170
        b = 8'h23; // 85
        mode = 2'b01;
        #10;
        
        // // Test Case 3: 2x2 multiplication
        // a = 8'b00001111; // 15
        // b = 8'b00000011; // 3
        // mode = 2'b10;
        // #10;
        
        // // Test Case 4: Signed multiplication (TODO: Verify implementation)
        // a = 8'b11111001; // -7 in signed 8-bit
        // b = 8'b00000110; // 6
        // mode = 2'b00;
        // #10;
        
        // // Test Case 5: Edge case (multiplying by zero)
        // a = 8'b00000000;
        // b = 8'b10101010;
        // mode = 2'b00;
        // #10;
        
        // // Test Case 6: Maximum values
        // a = 8'b11111111; // 255 (unsigned), -1 (signed)
        // b = 8'b11111111; // 255 (unsigned), -1 (signed)
        // mode = 2'b00;
        // #10;
        
        // Finish simulation
        $finish;
    end
    
    initial begin
        $monitor("Time: %0t | a: %b (%0d) | b: %b (%0d) | mode: %b | p: %b (%0d)", 
                 $time, a, a, b, b, mode, p, p);
    end
    
endmodule
