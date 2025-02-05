/*
    TODO:
        - Create external interface to access axi lite
        - Create testbench
*/

module axi_lite_slave #(
    // Add custom parameters here
    
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    // Global signals
    input logic i_aclk, i_aresetn,

    // Write Address Channel
    input logic [ADDR_WIDTH-1:0] i_awaddr,
	input logic i_awvalid,
    output logic o_awready,

    // Write Data Channel
    input logic [DATA_WIDTH-1:0] i_wdata,
    input logic [DATA_WIDTH/8-1:0] i_wstrb, // strobe can be ignored
	input logic i_wvalid,
    output logic o_wready,

	// Write Response Channel
    input logic i_bready,
    output logic o_bvalid, 
    output logic [1:0] o_bresp,

    // Read Address Channel
	input logic [ADDR_WIDTH-1:0] i_araddr,
    input logic i_arvalid,
    output logic o_arready,

    // Read Data Channel
    input logic i_rready,
    output logic [DATA_WIDTH-1:0] o_rdata,
    output logic o_rvalid, 
    output logic [1:0] o_rresp

    // Add custom signals here
);
    // AXI4LITE signals
    logic [ADDR_WIDTH-1:0]axi_awaddr, axi_araddr;
    logic axi_awready, axi_wready, axi_bvalid, axi_arready, axi_rvalid;
    logic [1:0] axi_bresp, axi_rresp;

    always_comb begin
        o_awready = axi_awready;
        o_wready = axi_wready;
        o_bresp = axi_bresp;
        o_bvalid = axi_bvalid;
        o_arready = axi_arready;
        o_rresp = axi_rresp;
        o_rvalid = axi_rvalid;
    end

    // State machine
    logic [1:0] state_write, state_read;
    localparam Idle = 2'b00, 
        Raddr = 2'b10,
        Rdata = 2'b11,
        Waddr = 2'b10,
        Wdata = 2'b11;
    
    // Write state machine

    /*
        Outstanding write transactions are not supported by the slave i.e., 
        master should assert bready to receive response on or 
        before it starts sending the new transaction
    */
    always @(posedge i_aclk) begin                                 
        if (~i_aresetn) begin                                 
            axi_awready <= 0;                                 
            axi_wready <= 0;                                 
            axi_bvalid <= 0;                                 
            axi_bresp <= 0;                                 
            axi_awaddr <= 0;                                 
            state_write <= Idle;                                 
        end else begin                                 
            case(state_write)                                 
            Idle: begin                                 
                if(i_aresetn == 1'b1) begin                                 
                    axi_awready <= 1'b1;                                 
                    axi_wready <= 1'b1;                                 
                    state_write <= Waddr;                                 
                end else 
                    state_write <= state_write;                                 
            end

            /*
                At this state, slave is ready to receive address along with 
                corresponding control signals and first data packet. 
                Response valid is also handled at this state   
            */                               
            Waddr: begin                                 
                if (i_awvalid && o_awready) begin                                 
                    axi_awaddr <= i_awaddr;  
                    if(i_wvalid) begin                                   
                        axi_awready <= 1'b1;                                 
                        state_write <= Waddr;                                 
                        axi_bvalid <= 1'b1;                                 
                    end else begin                                 
                        axi_awready <= 1'b0;                                 
                        state_write <= Wdata;                                 
                        if (i_bready && axi_bvalid) axi_bvalid <= 1'b0;                                 
                    end                                 
                end else begin                                 
                    state_write <= state_write;                                 
                    if (i_bready && axi_bvalid) axi_bvalid <= 1'b0;                                 
                end                                 
            end

            /*
                At this state, slave is ready to receive the data packets 
                until the number of transfers is equal to burst length
            */
            Wdata: begin                                 
                if (i_wvalid) begin                                 
                    state_write <= Waddr;                                 
                    axi_bvalid <= 1'b1;                                 
                    axi_awready <= 1'b1;                                 
                    end else begin                                 
                        state_write <= state_write;                                 
                        if (i_bready && axi_bvalid) axi_bvalid <= 1'b0;
                    end
                end
            endcase                                 
        end                                 
    end  

    // TODO: logic to handle storing of i_wdata

    always_ff @(posedge i_aclk ) begin 
        if (i_aresetn == 1'b0) begin
            mem <= 0;
        end else begin
            if (i_wvalid) begin
                mem <= i_wdata;
            end
        end
    end

    // Read state machine
    always @(posedge i_aclk) begin                                       
        if (i_aresetn == 1'b0) begin                                       
            //asserting initial values to all 0's during reset                                       
            axi_arready <= 1'b0;                                       
            axi_rvalid <= 1'b0;                                       
            axi_rresp <= 1'b0;                                       
            state_read <= Idle;                                       
        end else begin                                       
            case(state_read)
                //Initial state inidicating reset is done and ready to receive read/write transactions
                Idle: begin                                                
                    if (i_aresetn == 1'b1) begin                                       
                        state_read <= Raddr;                                       
                        axi_arready <= 1'b1;                                       
                    end else 
                        state_read <= state_read;                                       
                end
                //At this state, slave is ready to receive address along with corresponding control signals
                Raddr: begin 
                    if (i_arvalid && o_arready) begin                                       
                        state_read <= Rdata;                                       
                        axi_araddr <= i_araddr;                                       
                        axi_rvalid <= 1'b1;                                       
                        axi_arready <= 1'b0;                                       
                    end 
                        else state_read <= state_read;                                       
                end
                //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length
                Rdata: begin                                           
                    if (i_arvalid && o_arready) begin                                       
                        axi_rvalid <= 1'b0;                                       
                        axi_arready <= 1'b1;                                       
                        state_read <= Raddr;                                       
                    end 
                        else state_read <= state_read;                                       
                end                                       
            endcase                                       
        end                                       
    end
    
    // TODO: logic to handle reading
endmodule