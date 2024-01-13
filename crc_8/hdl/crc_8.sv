`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Michael Fallon
//
// Design Name: crc_8
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
// crc[31:0]=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
//
//////////////////////////////////////////////////////////////////////////////////

module crc_8 #(
    parameter [31:0]    P_RESIDUE = 32'hC704DD7B
    )(
    input   logic           clk,
    input   logic           rst_n,
    input   logic   [7:0]   data_in,
    input   logic           data_in_vld,
    input   logic           byte_in_vld,
    output  logic           crc_vld
    );

    wire    [7:0]   data;
    reg     [31:0]  crc_q;
    reg     [31:0]  crc_d;
    genvar          i;

    assign crc_vld = (crc_d == P_RESIDUE) & byte_in_vld;

    generate
        for (i=0; i<8; i=i+1)
            assign data[i]  = data_in[7-i];
    endgenerate

    always @(posedge clk) begin
        if(~rst_n) begin
            crc_q <= ~0;
        end

        else begin
            if (byte_in_vld) begin
                crc_q   <= data_in_vld ? crc_d : ~0;
            end
        end
    end

    always @(*) begin
        crc_d[0]  = crc_q[24] ^ crc_q[30] ^ data[0]   ^ data[6];
        crc_d[1]  = crc_q[24] ^ crc_q[25] ^ crc_q[30] ^ crc_q[31] ^ data[0]   ^ data[1]   ^ data[6]   ^ data[7];
        crc_d[2]  = crc_q[24] ^ crc_q[25] ^ crc_q[26] ^ crc_q[30] ^ crc_q[31] ^ data[0]   ^ data[1]   ^ data[2] ^ data[6] ^ data[7];
        crc_d[3]  = crc_q[25] ^ crc_q[26] ^ crc_q[27] ^ crc_q[31] ^ data[1]   ^ data[2]   ^ data[3]   ^ data[7];
        crc_d[4]  = crc_q[24] ^ crc_q[26] ^ crc_q[27] ^ crc_q[28] ^ crc_q[30] ^ data[0]   ^ data[2]   ^ data[3] ^ data[4] ^ data[6];
        crc_d[5]  = crc_q[24] ^ crc_q[25] ^ crc_q[27] ^ crc_q[28] ^ crc_q[29] ^ crc_q[30] ^ crc_q[31] ^ data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
        crc_d[6]  = crc_q[25] ^ crc_q[26] ^ crc_q[28] ^ crc_q[29] ^ crc_q[30] ^ crc_q[31] ^ data[1]   ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
        crc_d[7]  = crc_q[24] ^ crc_q[26] ^ crc_q[27] ^ crc_q[29] ^ crc_q[31] ^ data[0]   ^ data[2]   ^ data[3] ^ data[5] ^ data[7];
        crc_d[8]  = crc_q[0]  ^ crc_q[24] ^ crc_q[25] ^ crc_q[27] ^ crc_q[28] ^ data[0]   ^ data[1]   ^ data[3] ^ data[4];
        crc_d[9]  = crc_q[1]  ^ crc_q[25] ^ crc_q[26] ^ crc_q[28] ^ crc_q[29] ^ data[1]   ^ data[2]   ^ data[4] ^ data[5];
        crc_d[10] = crc_q[2]  ^ crc_q[24] ^ crc_q[26] ^ crc_q[27] ^ crc_q[29] ^ data[0]   ^ data[2]   ^ data[3] ^ data[5];
        crc_d[11] = crc_q[3]  ^ crc_q[24] ^ crc_q[25] ^ crc_q[27] ^ crc_q[28] ^ data[0]   ^ data[1]   ^ data[3] ^ data[4];
        crc_d[12] = crc_q[4]  ^ crc_q[24] ^ crc_q[25] ^ crc_q[26] ^ crc_q[28] ^ crc_q[29] ^ crc_q[30] ^ data[0] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6];
        crc_d[13] = crc_q[5]  ^ crc_q[25] ^ crc_q[26] ^ crc_q[27] ^ crc_q[29] ^ crc_q[30] ^ crc_q[31] ^ data[1] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7];
        crc_d[14] = crc_q[6]  ^ crc_q[26] ^ crc_q[27] ^ crc_q[28] ^ crc_q[30] ^ crc_q[31] ^ data[2]   ^ data[3] ^ data[4] ^ data[6] ^ data[7];
        crc_d[15] = crc_q[7]  ^ crc_q[27] ^ crc_q[28] ^ crc_q[29] ^ crc_q[31] ^ data[3]   ^ data[4]   ^ data[5] ^ data[7];
        crc_d[16] = crc_q[8]  ^ crc_q[24] ^ crc_q[28] ^ crc_q[29] ^ data[0]   ^ data[4]   ^ data[5];
        crc_d[17] = crc_q[9]  ^ crc_q[25] ^ crc_q[29] ^ crc_q[30] ^ data[1]   ^ data[5]   ^ data[6];
        crc_d[18] = crc_q[10] ^ crc_q[26] ^ crc_q[30] ^ crc_q[31] ^ data[2]   ^ data[6]   ^ data[7];
        crc_d[19] = crc_q[11] ^ crc_q[27] ^ crc_q[31] ^ data[3]   ^ data[7];
        crc_d[20] = crc_q[12] ^ crc_q[28] ^ data[4];
        crc_d[21] = crc_q[13] ^ crc_q[29] ^ data[5];
        crc_d[22] = crc_q[14] ^ crc_q[24] ^ data[0];
        crc_d[23] = crc_q[15] ^ crc_q[24] ^ crc_q[25] ^ crc_q[30] ^ data[0]   ^ data[1] ^ data[6];
        crc_d[24] = crc_q[16] ^ crc_q[25] ^ crc_q[26] ^ crc_q[31] ^ data[1]   ^ data[2] ^ data[7];
        crc_d[25] = crc_q[17] ^ crc_q[26] ^ crc_q[27] ^ data[2]   ^ data[3];
        crc_d[26] = crc_q[18] ^ crc_q[24] ^ crc_q[27] ^ crc_q[28] ^ crc_q[30] ^ data[0] ^ data[3] ^ data[4] ^ data[6];
        crc_d[27] = crc_q[19] ^ crc_q[25] ^ crc_q[28] ^ crc_q[29] ^ crc_q[31] ^ data[1] ^ data[4] ^ data[5] ^ data[7];
        crc_d[28] = crc_q[20] ^ crc_q[26] ^ crc_q[29] ^ crc_q[30] ^ data[2]   ^ data[5] ^ data[6];
        crc_d[29] = crc_q[21] ^ crc_q[27] ^ crc_q[30] ^ crc_q[31] ^ data[3]   ^ data[6] ^ data[7];
        crc_d[30] = crc_q[22] ^ crc_q[28] ^ crc_q[31] ^ data[4]   ^ data[7];
        crc_d[31] = crc_q[23] ^ crc_q[29] ^ data[5];
    end
    
    initial begin
        $dumpfile("crc_8.vcd");
        $dumpvars();
    end


endmodule
