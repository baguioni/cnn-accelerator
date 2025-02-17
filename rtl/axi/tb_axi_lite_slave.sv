`timescale 1ns / 1ps

module axi_lite_slave_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // Clock and Reset
    logic i_aclk;
    logic i_aresetn;

    // Write Address Channel
    logic [ADDR_WIDTH-1:0] i_awaddr;
    logic i_awvalid;
    logic o_awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0] i_wdata;
    logic [DATA_WIDTH/8-1:0] i_wstrb;
    logic i_wvalid;
    logic o_wready;

    // Write Response Channel
    logic i_bready;
    logic o_bvalid; 
    logic [1:0] o_bresp;

    // Read Address Channel
    logic [ADDR_WIDTH-1:0] i_araddr;
    logic i_arvalid;
    logic o_arready;

    // Read Data Channel
    logic i_rready;
    logic [DATA_WIDTH-1:0] o_rdata;
    logic o_rvalid; 
    logic [1:0] o_rresp;

    // Instantiate the DUT (Device Under Test)
    axi_lite_slave_mem #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_aclk(i_aclk),
        .i_aresetn(i_aresetn),
        .i_awaddr(i_awaddr),
        .i_awvalid(i_awvalid),
        .o_awready(o_awready),
        .i_wdata(i_wdata),
        .i_wstrb(i_wstrb),
        .i_wvalid(i_wvalid),
        .o_wready(o_wready),
        .i_bready(i_bready),
        .o_bvalid(o_bvalid),
        .o_bresp(o_bresp),
        .i_araddr(i_araddr),
        .i_arvalid(i_arvalid),
        .o_arready(o_arready),
        .i_rready(i_rready),
        .o_rdata(o_rdata),
        .o_rvalid(o_rvalid),
        .o_rresp(o_rresp)
    );

    // Clock Generation (100MHz)
    always #5 i_aclk = ~i_aclk;

    // Task to perform an AXI write operation
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            i_awaddr = addr;
            i_awvalid = 1;
            i_wdata = data;
            i_wvalid = 1;
            i_wstrb = 4'b1111;  // Enable all bytes
            i_bready = 1;
            wait(o_awready == 1);
            i_awvalid = 0;
            wait(o_wready == 1);
            i_wvalid = 0;

            wait(o_bvalid);
            $display("o_bvalid == 1");
            $display("WRITE: Address = 0x%h, Data = 0x%h, Response = 0x%h", addr, data, o_bresp);
            i_bready = 0;
        end
    endtask

    // Task to perform an AXI read operation
    task axi_read(input [ADDR_WIDTH-1:0] addr);
        begin
            i_araddr = addr;
            i_arvalid = 1;
            i_rready = 1;

            wait(o_arready);
            i_arvalid = 0;

            wait(o_rvalid);
            $display("READ: Address = 0x%h, Data = 0x%h, Response = 0x%h", addr, o_rdata, o_rresp);
            i_rready = 0;
        end
    endtask

    // Main Testbench Execution
    initial begin
        // Initialize signals
        i_aclk = 0;
        i_aresetn = 0;
        i_awaddr = 0;
        i_awvalid = 0;
        i_wdata = 0;
        i_wstrb = 0;
        i_wvalid = 0;
        i_bready = 0;
        i_araddr = 0;
        i_arvalid = 0;
        i_rready = 0;

        // Apply Reset
        #20;
        i_aresetn = 1;
        $display("RESET COMPLETE");

        // Perform Write and Read Transactions
        #10;
        axi_write(32'h00000000, 32'hDEADBEEF);  // Write 0xDEADBEEF to address 0x00000000
        #10;
        // axi_read(32'h00000000);                 // Read back from address 0x00000000

        #10;
        axi_write(32'h00000004, 32'hCAFEBABE);  // Write 0xCAFEBABE to address 0x00000004
        #10;
        // axi_read(32'h00000004);                 // Read back from address 0x00000004

        #10;
        $display("TEST COMPLETED");
        $finish;
    end

    // VCD Dump for waveform analysis
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars;
    end

endmodule
