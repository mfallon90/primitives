`timescale 1ns / 1ps

`define PTR_BITS ($clog2(P_DEPTH))
`define WR_PTR_INV ({~wr_ptr_gry[`PTR_BITS:`PTR_BITS-1], wr_ptr_gry[`PTR_BITS-2:0]})


/*
Author: Michael Fallon

Design Name: async_fifo
Tool Versions: Vivado 2020.2

Description: This is a wrapper to instantiate the different components of the
asynchronous fifo. The synchronizing flip flops for cdc are located in this
module as well as an instance of a dual-port block ram, which acts as the
fifo memory. The binary-to-gray conversion blocks are also instantiated here.
A gray code counter in conjunction with synchronizing flip flops is used to 
achieve CDC. The binary read and write pointers are first converted to gray 
code before being synchronized into the opposite clock domain for comparison.

For example, the write pointer is converted to gray code and synced into the
read domain. If the synced write pointer equals to read pointer then the FIFO
is either full or empty, and is determined using the MSB of the pointers.

For this design to work, the depth of the fifo MUST be a power of 2. This is
because a mod-n counter is used for read and write pointers, meaning that the
counter will only accurately and correctly roll over if the depth is a power of 2

Note that the binary to gray converters are slightly different for the read
and write domains. The write domain outputs a registered version of the gray
code pointer, while the read domain outputs a combinational version of the 
pointer. This is because the FIFO is a synchronous read, meaning that the 
extra clock cycle required to read from the FIFO requires that the pointer needs
to arrive one clock cycle early. This is required to infer a block-ram in
xilinx. If you used an asynchronous read FIFO, then you would use the registered
read pointer instead.

Parameters
    P_DEPTH: describes the depth of the FIFO. Must be a multiple of 1024
    in order to infer a block ram in xilinx tools

    P_WIDTH: the width of the data word/FIFO

Macros
    PTR_BITS: number of bits to address the FIFO. One additional bit is
    added to as the MSB and is used for empty and full logic.

    WR_PTR_INV: inverts the MSB of the write pointer for comparison with
    the synchronized read pointer. This is only done in the write domain
    for full flag comparison which requires that every bit EXCEPT for the
    MSB be identical. The empty comparison requires that the entire pointers
    be equal, including the MSB's.
*/

module async_fifo #(
    parameter   P_DEPTH = 1024,
    parameter   P_WIDTH = 8
    )(
    // Write domain
    input   wire                    wr_clk,
    input   wire                    wr_rst_n,
    input   wire    [P_WIDTH-1:0]   wr_data,
    input   wire                    wr_vld,
    output  wire                    wr_rdy,

    // Read domain
    input   wire                    rd_clk,
    input   wire                    rd_rst_n,
    output  wire    [P_WIDTH-1:0]   rd_data,
    output  wire                    rd_vld,
    input   wire                    rd_rdy
    );

    ////////////////////////////////
    //    Write Domain Signals    //
    ////////////////////////////////

    wire                                 wr_full;
    wire                                 wr_en;
    wire                 [`PTR_BITS:0]   wr_ptr_bin;
    wire                 [`PTR_BITS:0]   wr_ptr_gry;
 (* keep = "true" *) reg [`PTR_BITS:0]   sync_rd_ptr0;
 (* keep = "true" *) reg [`PTR_BITS:0]   sync_rd_ptr1;

    ///////////////////////////////
    //    Read Domain Signals    //
    ///////////////////////////////

    wire                                 rd_empty;
    wire                                 rd_en;
    wire                 [`PTR_BITS:0]   rd_ptr_bin;
    wire                 [`PTR_BITS:0]   rd_ptr_gry;
 (* keep = "true" *) reg [`PTR_BITS:0]   sync_wr_ptr0;
 (* keep = "true" *) reg [`PTR_BITS:0]   sync_wr_ptr1;

    //////////////////////////////////
    //    Concurrent Assignments    //
    //////////////////////////////////

    assign  wr_en       = wr_vld & ~wr_full;
    assign  wr_rdy      = ~wr_full;
    assign  wr_full     = (`WR_PTR_INV == sync_rd_ptr1);
    assign  rd_vld      = ~rd_empty;
    assign  rd_en       = rd_rdy & ~rd_empty;
    assign  rd_empty    = (rd_ptr_gry == sync_wr_ptr1);

    /////////////////////////////////////////////////////
    //    Synchronizing flip flops for Read Pointer    //
    /////////////////////////////////////////////////////

    always @(posedge wr_clk) begin
        if (~wr_rst_n) begin
            sync_rd_ptr0    <= 0;
            sync_rd_ptr1    <= 0;
        end

        else begin
            sync_rd_ptr0    <= rd_ptr_gry;
            sync_rd_ptr1    <= sync_rd_ptr0;
        end
    end

    //////////////////////////////////////////////////////
    //    Synchronizing flip flops for Write Pointer    //
    //////////////////////////////////////////////////////
    
    always @(posedge rd_clk) begin
        if (~rd_rst_n) begin
            sync_wr_ptr0    <= 0;
            sync_wr_ptr1    <= 0;
        end

        else begin
            sync_wr_ptr0    <= wr_ptr_gry;
            sync_wr_ptr1    <= sync_wr_ptr0;
        end
    end

    ////////////////////////////////////
    //    Dual Port FIFO Block Ram    //
    ////////////////////////////////////

    fifo_bram #(
            .P_DEPTH (P_DEPTH),
            .P_WIDTH (P_WIDTH))
        fifo_module (
            .wr_clk     (wr_clk),
            .wr_addr    (wr_ptr_bin[`PTR_BITS-1:0]),
            .wr_en      (wr_en),
            .wr_data    (wr_data),
            .rd_clk     (rd_clk),
            .rd_addr    (rd_ptr_bin[`PTR_BITS-1:0]),
            .rd_data    (rd_data)
        );

    ////////////////////////////////////
    //    Binary to Gray Converter    //
    ////////////////////////////////////

    bin_gry_ctr #(
            .P_NUM_BITS (`PTR_BITS+1))
        wr_ptr_calc (
            .clk            (wr_clk),
            .rst_n          (wr_rst_n),
            .en             (wr_en),
            .bin_cnt_reg    (wr_ptr_bin),
            .gry_cnt_reg    (wr_ptr_gry)
        );

    ////////////////////////////////////
    //    Binary to Gray Converter    //
    ////////////////////////////////////

    bin_gry_ctr #(
            .P_NUM_BITS (`PTR_BITS+1))
        rd_ptr_calc (
            .clk            (rd_clk),
            .rst_n          (rd_rst_n),
            .en             (rd_en),
            .bin_cnt_comb   (rd_ptr_bin),
            .gry_cnt_reg    (rd_ptr_gry)
        );

    // initial begin
    //     $dumpfile("async_fifo.vcd");
    //     $dumpvars();
    // end


endmodule
