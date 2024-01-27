`timescale 1ns / 1ps
`define DATA_BITS ((HEX == 1) ? 4*NUM_DIGITS : $clog2(10**NUM_DIGITS))

module seven_segment_display #(
    parameter int NUM_DIGITS    = 4,
    parameter int HEX           = 0,
    parameter int CLK_FREQ      = 125 //MHz
    )(
    input  wire                   clk,
    input  wire                   rst,
    input  wire  [`DATA_BITS-1:0] data_in,
    output logic [NUM_DIGITS-1:0] enable,
    output logic [7:0]            led_out
    );

    localparam int TARGET_PERIOD = 16; //ms
    localparam int CLOCK_CYCLES  = TARGET_PERIOD*CLK_FREQ*100;

    logic [$clog2(CLOCK_CYCLES)-1:0] refresh_counter;
    logic [$clog2(NUM_DIGITS)-1:0]   enable_select;
    logic                            inc_select;

    always_ff @(posedge clk) begin
        if (rst == 1) begin
            refresh_counter <= '0;
            enable_select   <= '0;
        end else begin
            refresh_counter <= refresh_counter+1;
            enable_select   <= enable_select + inc_select;
            if (enable_select == NUM_DIGITS) begin
                enable_select   <= '0;
            end
        end
    end

    always_comb begin
        enable = '1;
        inc_select = (refresh_counter == '1);
        enable[enable_select] = 1'b0;

        if (HEX == 0) begin
            case (data_in)
                0:       led_out = 8'b00000011;
                1:       led_out = 8'b10011111;
                2:       led_out = 8'b00100101;
                3:       led_out = 8'b00001101;
                4:       led_out = 8'b10011001;
                5:       led_out = 8'b01001001;
                6:       led_out = 8'b01000001;
                7:       led_out = 8'b00011111;
                8:       led_out = 8'b00000001;
                9:       led_out = 8'b00001001;
                default: led_out = '1;
            endcase
        end else begin
            case (data_in)
                0:       led_out = 8'b00000011;
                1:       led_out = 8'b10011111;
                2:       led_out = 8'b00100101;
                3:       led_out = 8'b00001101;
                4:       led_out = 8'b10011001;
                5:       led_out = 8'b01001001;
                6:       led_out = 8'b01000001;
                7:       led_out = 8'b00011111;
                8:       led_out = 8'b00000001;
                9:       led_out = 8'b00001001;
                10:      led_out = 8'b00010001;
                11:      led_out = 8'b11000001;
                12:      led_out = 8'b01100011;
                13:      led_out = 8'b10000101;
                14:      led_out = 8'b01100001;
                15:      led_out = 8'b01110001;
                default: led_out = '1;
            endcase
        end
    end

endmodule

