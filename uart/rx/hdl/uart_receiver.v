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

module uart_receiver # (
    parameter   integer P_NUM_BITS  = 8,
    parameter   integer P_CLK_FREQ  = 100,
    parameter   integer P_BAUD_RATE = 115200,
    parameter   integer P_NUM_STOP  = 2,
    parameter   integer P_PARITY    = 1
    )(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire                        uart_rx,
    output  wire    [P_NUM_BITS-1:0]    uart_word,
    output  wire                        uart_word_vld,
    input   wire                        uart_word_rdy
    );

    function vote;
        input   [2:0] x;
        begin
            vote = (x[0]&x[1])|(x[0]&x[2])|(x[1]&x[2]);
        end
    endfunction
    
    localparam  integer CLKS_PER_BIT    = P_CLK_FREQ*1000000/P_BAUD_RATE;
    localparam  integer SAMPLE_INT      = CLKS_PER_BIT/6;
    localparam  integer SAMPLE_1        = CLKS_PER_BIT/2 - SAMPLE_INT;
    localparam  integer SAMPLE_2        = CLKS_PER_BIT/2;
    localparam  integer SAMPLE_3        = CLKS_PER_BIT/2 + SAMPLE_INT;

    localparam  [2:0]   S_IDLE          = 3'b000;
    localparam  [2:0]   S_START         = 3'b001;
    localparam  [2:0]   S_RX            = 3'b010;
    localparam  [2:0]   S_PAR           = 3'b011;
    localparam  [2:0]   S_STOP          = 3'b100;

    reg     [2:0]                       state;
    reg     [$clog2(CLKS_PER_BIT)-1:0]  cnt;
    reg     [3:0]                       bits;
    reg     [P_NUM_BITS-1:0]            temp;
    reg     [P_NUM_BITS-1:0]            data;
    reg     [2:0]                       samples;
    reg                                 done;
    reg                                 par_rcv;
    wire                                par_calc;
    wire                                sample_now;

    assign sample_now       = ((cnt == SAMPLE_1)||(cnt == SAMPLE_2)||(cnt == SAMPLE_3));
    assign par_calc         = ^temp;
    assign uart_word_vld    = done;
    assign uart_word        = data;

    always @(posedge clk) begin
        if (~rst_n) begin
            state       <= S_IDLE;
            temp        <= 0;
            data        <= 0;
            cnt         <= 0;
            bits        <= 0;
            samples     <= 0;
            par_rcv     <= 0;
            done        <= 1'b0;
        end

        else begin

            if (uart_word_rdy & done) begin
                done    <= 0;
                data    <= 0;
            end

            case (state)
                S_IDLE: begin
                    // done    <= 0;
                    if (~uart_rx) begin
                        state   <= S_START;
                        cnt     <= cnt+1;
                    end
                end

                S_START: begin
                    cnt     <= cnt+1;

                    if (sample_now) begin
                        samples     <= {uart_rx, samples[2:1]};
                    end

                    else if (cnt == CLKS_PER_BIT-1) begin
                        if (~vote(samples)) begin
                            state   <= S_RX;
                            cnt     <= 0;
                        end 
                        
                        else begin
                            state   <= S_IDLE;
                            cnt     <= 0;
                        end
                    end
                end

                S_RX: begin
                    cnt     <= cnt+1;
                    if (sample_now) begin
                        samples     <= {uart_rx, samples[2:1]};
                    end
                    
                    else if (cnt == CLKS_PER_BIT-1) begin
                        temp    <= {vote(samples),temp[P_NUM_BITS-1:1]};

                        if (bits < P_NUM_BITS-1) begin
                            cnt     <= 0;
                            bits    <= bits+1;
                        end

                        else begin
                            state       <= (P_PARITY == 0) ? S_STOP : S_PAR;
                            cnt         <= 0;
                            bits        <= 0;
                        end
                    end
                end

                S_PAR: begin
                    cnt     <= cnt+1;
                    if (sample_now) begin
                        samples     <= {uart_rx, samples[2:1]};
                    end
                    
                    else if (cnt == CLKS_PER_BIT-1) begin
                        par_rcv     <= vote(samples);
                        state       <= S_STOP;
                        cnt         <= 0;
                    end
                end

                S_STOP: begin
                    cnt     <= cnt+1;
                    if (cnt == CLKS_PER_BIT-1) begin
                        if (bits < P_NUM_STOP-1) begin
                            cnt     <= 0;
                            bits    <= bits+1;
                        end

                        else begin
                            state       <= S_IDLE;
                            cnt         <= 0;
                            bits        <= 0;
                            data        <= temp;
                            par_rcv     <= 0;
                            case (P_PARITY)
                                0: done <= 1;
                                1: done <= ~(par_rcv ^ par_calc);
                                2: done <= (par_rcv ^ par_calc);
                            endcase
                        end
                    end
                end
            endcase
        end
    end
    


    initial begin
        $dumpfile("uart_receiver.vcd");
        $dumpvars();
    end
    
   endmodule
