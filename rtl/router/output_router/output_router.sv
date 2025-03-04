module output_router #(
    parameter int SPAD_ADDR_WIDTH = 8,
    parameter int SPAD_DATA_WIDTH = 16,                 // SPAD can have 2B per address
    parameter int ROUTER_COUNT = 4,                     // Also # of PE in systolic array
    parameter int DATA_WIDTH = 8,                       // PE output width
    parameter int MEMBER_CNT = (SPAD_DATA_WIDTH+DATA_WIDTH-1)/DATA_WIDTH,
    parameter int GROUP_CNT  = (ROUTER_COUNT+MEMBER_CNT-1)/MEMBER_CNT
) (
    input logic i_clk, i_nrst, i_en,
    // ifmap signals
    input  logic [0:ROUTER_COUNT-1][DATA_WIDTH*2-1:0] i_ifmap,
    input  logic [ROUTER_COUNT-1:0] i_valid,

    output logic [SPAD_DATA_WIDTH-1:0] o_data_out,
    output logic o_valid, o_done
);
    localparam EMPTY = MEMBER_CNT*GROUP_CNT - ROUTER_COUNT;
    
    logic [0:GROUP_CNT-1][SPAD_DATA_WIDTH-1:0] output_data;
    logic [0:MEMBER_CNT*GROUP_CNT-1][DATA_WIDTH*2-1:0] extended_ifmap;
    logic [MEMBER_CNT*GROUP_CNT-1:0] extended_valid;

    genvar i, j;
    generate
        for ( i=0; i<GROUP_CNT; i++) begin
            logic [0:MEMBER_CNT-1][DATA_WIDTH*2-1:0] unpacked_data;
            logic [SPAD_DATA_WIDTH-1:0] packed_data;
            
            assign unpacked_data = extended_ifmap[MEMBER_CNT*i+:MEMBER_CNT];

            // TODO: properly handle converting 16-bit to 8-bit
            for (j=0; j<MEMBER_CNT; j++) begin
                assign packed_data[(MEMBER_CNT-j-1)*DATA_WIDTH+:DATA_WIDTH] = 
                    (!extended_valid[i*MEMBER_CNT+j])? 0 : unpacked_data[j][DATA_WIDTH-1:0];
            end

            assign output_data[i] = packed_data;
        end
    endgenerate

    localparam IDLE = 0;
    localparam OUT  = 1;
    logic state;

    logic reg_en;

    logic out_en;
    assign out_en = i_en & ~o_done;

    logic [$clog2(GROUP_CNT)-1:0] count;
    always_ff @(posedge i_clk) begin
        if (!i_nrst) begin
            state   <= IDLE;
            count   <= 0;
            o_valid <= 0;
            reg_en <= 0;
            o_done  <= 0;

            extended_ifmap <= 0;
            extended_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (out_en) begin
                        state          <= OUT;
                        o_valid        <= 1;
                        extended_ifmap <= i_ifmap << (EMPTY * DATA_WIDTH * 2);
                        extended_valid <= i_valid;
                    end else begin
                        state          <= IDLE;
                        o_valid        <= 0;
                        extended_ifmap <= 0;
                        extended_valid <= 0;
                        o_done         <= 0;
                    end

                    o_done <= 0;
                    count <= 0;

                end
                OUT : begin
                    if (count < GROUP_CNT-1) begin
                        count <= count + 1;
                    end else begin
                        state   <= IDLE;
                        count   <= 0;
                        o_valid <= 0;
                        o_done  <= 1;
                        
                        extended_ifmap <= 0;
                        extended_valid <= 0;
                    end
                end
                default: state <= IDLE; 
            endcase
        end
    end

    assign o_data_out = (!(state==OUT))? 0 : output_data[count];

endmodule