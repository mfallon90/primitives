`timescale 1ns / 1ps
`define ADDR_BITS ($clog2(P_DEPTH))

/*
Author: Michael Fallon

Design Name:  fifo_bram
Tool Versions: Vivado 2020.2

Description: This design infers a dual-port block ram used
as the basic memory module for the FIFO. The read and write
ports are both synchronous and may use independent clocks.

Parameters
    P_DEPTH: the depth of the FIFO in terms of words. Note
             that this must be a multiple of 1024 to confrom
             with xilinx bram standards
    P_WIDTH: the number of bits in the fifo word. This should
             be an integer multiple of either 8 or 9

*/

module fifo_bram #(
    parameter integer   P_DEPTH = 1024,
    parameter integer   P_WIDTH = 8
    )(
    input   wire                        wr_clk,
    input   wire    [`ADDR_BITS-1:0]    wr_addr,
    input   wire                        wr_en,
    input   wire    [P_WIDTH-1:0]       wr_data,

    input   wire                        rd_clk,
    input   wire    [`ADDR_BITS-1:0]    rd_addr,
    output  reg     [P_WIDTH-1:0]       rd_data
    );


    reg [P_WIDTH-1:0] bram [0:(P_DEPTH)-1];
    integer i;

    initial begin
        for (i=0; i<P_DEPTH; i=i+1) begin
            bram[i] = 0;
        end
    end

    // Synchronous Writes
    always@(posedge wr_clk) begin
        if (wr_en) begin
            bram[wr_addr]   <= wr_data;
        end
    end

    // Synchronous Reads
    always@(posedge rd_clk) begin
        rd_data <= bram[rd_addr];
    end

endmodule