`timescale 1ns / 1ps
`define CTRL_LEN 14

//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Michael Fallon
//
// Design Name: eth_rx_fsm
// Module Name: fm_synth_top
// Tool Versions: Vivado 2020.2
//
// Description: This module receives data from phy using standard MII protocol.
// Data is received in nibbles and sent out as bytes, along with a byte valid 
// flag to indicate a valid byte. The MII protocol specifies that data is received
// Most Significant Byte first, but within that byte, the Least Significant Nibble
// is received first, followed by the Most significant nibble. So if the following
// data is seen on rx_data : 0xA 0xC 0x4 0xD then the intended bytes are 0xCA 0xD4
//
// Note that the MAC address for the PHY must be provided with the nibbles
// inverted in order to conform to the MII receive data format
//
//////////////////////////////////////////////////////////////////////////////////

module eth_rx_fsm
    (
    // RX signals
    input   logic           clk,
    input   logic           rst_n,
    input   logic   [7:0]   data_in,
    input   logic           data_in_vld,
    input   logic           byte_in_vld,
    input   logic           crc_vld,
    output  logic   [7:0]   data_out,
    output  logic           data_out_vld,
    output  logic   [123:0] ctrl,
    output  logic           ctrl_vld
    );

    localparam      S_IDLE  = 0;
    localparam      S_PKT   = 1;

    logic           state;
    logic   [10:0]  byte_cnt;
    logic   [103:0] control;
    logic           frm_done;

    assign frm_done     = crc_vld | ~data_in_vld;
    assign data_out_vld = (state == S_PKT) & byte_in_vld;
    assign data_out     = data_in;

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            state           <= S_IDLE;
            byte_cnt        <= 0;
            control         <= 0;
            ctrl_vld        <= 0;
            ctrl            <= 0;
        end

        else begin
            ctrl_vld    <= 0;
            if (byte_in_vld) begin

                control     <= {control[95:0], data_in};
                byte_cnt    <= byte_cnt+1;
                ctrl_vld    <= 0;

                case (state)
                    S_IDLE: begin
                        if (~data_in_vld) begin
                            byte_cnt    <= 0;
                        end
                        else if (byte_cnt == `CTRL_LEN-1) begin
                            state           <= S_PKT;
                            byte_cnt        <= 0;
                            ctrl[123:12]    <= {control, data_in};
                        end
                    end

                    S_PKT: begin
                        if (frm_done) begin
                            ctrl_vld        <= 1'b1;
                            ctrl[11:0]      <= { ~crc_vld, byte_cnt};
                            state           <= S_IDLE;
                            byte_cnt        <= 0;
                        end
                    end
                endcase
            end
        end
    end

    // initial begin
    //     $dumpfile("eth_rx_fsm.vcd");
    //     $dumpvars();
    // end


endmodule