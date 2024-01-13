`timescale 1ns / 1ps

/*
Author: Michael Fallon

Design Name:  modn_counter
Tool Versions: Vivado 2020.2

Description: This is a binary to gray code conversion module. The input
is an unsigned binary number and the output is the gray code version.

The basic design is a binary counter which increments each clock cycle
that the enable bit is asserted. Note that this is a mod-n counter,
meaning that this design will increment until it reaches a value of
2**P_NUM_BITS - 1, at which point it rolls back over to zero.

The algorithm to convert to gray code is as follows:
    - The MSB is passed directly through
    - For all other bits, the gray code bit at index i can be found by
      XORing the ith bit in the binary counter with the ith+1 bit

    example: binary 1011 -> gray 1110
        bit 3: 1 -> 1       (MSB passed directly through)
        bit 2: 0 -> 0^1 = 1 (xor bits 2 and 3 from binary counter)
        bit 1: 1 -> 1^0 = 1 (xor bits 1 and 2 from binary counter)
        bit 0: 1 -> 1^1 = 0 (xor bits 0 and 1 from binary counter)

The output of the binary and gray counter is registered. The next binary
count is also made available combinationally to drive the synchronous read

Parameters
    P_NUM_BITS: the number of bits in the mod-n counter

*/

module modn_counter #(
    parameter   P_NUM_BITS = 8
    )(
    // Write domain
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire                        en,
    output  wire    [P_NUM_BITS-1:0]    cnt_cmb,
    output  wire    [P_NUM_BITS-1:0]    cnt_reg
    );

    wire    [P_NUM_BITS-1:0]    cnt_next;
    reg     [P_NUM_BITS-1:0]    cnt_curr;

    assign cnt_next = cnt_curr + {{P_NUM_BITS-1{1'b0}}, en};

    assign cnt_cmb = cnt_next;
    assign cnt_reg = cnt_curr;


    always @(posedge clk) begin
        if (~rst_n) begin
            cnt_curr    <= 0;
        end

        else begin
            cnt_curr    <= cnt_next;
        end
    end
endmodule