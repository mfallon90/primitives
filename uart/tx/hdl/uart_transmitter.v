`timescale 1ns / 1ps
`define CLKS_PER_BIT ((P_CLK_FREQ/P_BAUD_RATE)*1000)

/*
Author: Michael Fallon

Create Date: 11/02/2021 06:12:08 AM
Design Name: UART
Tool Versions: Vivado 2020.2
Description: 

Dependencies: 

Revision:
Revision 0.01 - File Created
Additional Comments: 

     clk frequency       = 100 MHz
     baud rate           = 115.2 Kbs
     clk cycles per bit  = 868
     sample point        = 434
*/

module uart_transmitter # (
    parameter   integer P_NUM_BITS  = 8,
    parameter   integer P_CLK_FREQ  = 100,
    parameter   integer P_BAUD_RATE = 115200,
    parameter   integer P_NUM_STOP  = 2,
    parameter   integer P_PARITY    = 2
    )(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire    [P_NUM_BITS-1:0]    data_in,
    input   wire                        data_in_vld,
    output  wire                        data_in_rdy,
    output  reg                         uart_tx
    );

    
    localparam  integer CLKS_PER_BIT    = P_CLK_FREQ*1000000/P_BAUD_RATE;
    localparam  integer TX_BITS = (P_PARITY == 0) ? P_NUM_BITS+P_NUM_STOP+1 : P_NUM_BITS+P_NUM_STOP+2;

    localparam  [1:0]   S_IDLE  = 1'b0;
    localparam  [1:0]   S_TX    = 1'b1;

    function [TX_BITS-1:0] frame;
        input   [P_NUM_BITS-1:0] x;
        begin
            case (P_PARITY)
                0: frame = {{P_NUM_STOP{1'b1}}, x, 1'b0};
                1: frame = {{P_NUM_STOP{1'b1}}, ^x, x, 1'b0};
                2: frame = {{P_NUM_STOP{1'b1}}, ~(^x), x, 1'b0};
            endcase
        end
    endfunction

    reg                                 state;
    reg     [$clog2(CLKS_PER_BIT)-1:0]  cnt;
    reg     [$clog2(TX_BITS)-1:0]       bits;
    reg     [TX_BITS-1:0]               temp;

    assign  data_in_rdy = ~state;

    always @(posedge clk) begin
        if (~rst_n) begin
            state       <= S_IDLE;
            temp        <= 0;
            cnt         <= 0;
            bits        <= 0;
        end

        else begin
            case (state)
                S_IDLE: begin
                    uart_tx     <= 1'b1;
                    if (data_in_vld) begin
                        temp    <= frame(data_in);
                        state   <= S_TX;
                    end
                end

                S_TX: begin
                    cnt         <= cnt+1;
                    uart_tx     <= temp[0];
                    
                    if (cnt == CLKS_PER_BIT-1) begin
                        if (bits < TX_BITS-1) begin
                            temp    <= temp >> 1;
                            cnt     <= 0;
                            bits    <= bits+1;
                        end

                        else begin
                            state       <= S_IDLE;
                            uart_tx     <= 1'b1;
                            cnt         <= 0;
                            bits        <= 0;
                        end
                    end
                end
            endcase
        end
    end


    initial begin
        $dumpfile("uart_transmitter.vcd");
        $dumpvars();
    end
    
   endmodule
