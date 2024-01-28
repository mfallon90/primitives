`timescale 1ns / 1ps

module seven_segment_display #(
    parameter int HEX           = 0,
    parameter int DATA_BITS     = $clog2(9999),
    parameter int CLK_FREQ      = 125, //MHz
    parameter int SIM           = 1
    )(
    input  wire                   clk,
    input  wire                   reset,
    input  wire  [DATA_BITS-1:0]  data_in,
    input  wire                   data_in_valid,
    output logic [3:0]            enable,
    output logic [7:0]            led_out
    );

    localparam int TARGET_PERIOD = 16; //ms
    localparam int CLOCK_CYCLES  = TARGET_PERIOD*CLK_FREQ*100;
    localparam int COUNTER_BITS  = SIM ? 8 : $clog2(CLOCK_CYCLES)+2;

    logic [15:0] packed_bcd;
    logic [15:0] packed_bcd_reg;
    logic [3:0]  bcd;
    logic        packed_bcd_valid;

    double_dabble #(
        .NUM_BITS (DATA_BITS)
    ) i_double_dabble (
        .clk                  (clk),
        .reset                (reset),
        .binary_in            (data_in),
        .binary_in_valid      (data_in_valid),
        .packed_bcd_out       (packed_bcd),
        .packed_bcd_out_valid (packed_bcd_valid)
    );

    always_ff @(posedge clk) begin
        if (packed_bcd_valid == 1) begin
            packed_bcd_reg <= packed_bcd;
        end
    end

    logic [COUNTER_BITS-1:0] refresh_counter;
    logic [1:0]              enable_select;

    assign enable_select = refresh_counter[$high(refresh_counter)-:2];

    always_ff @(posedge clk) begin
        if (reset == 1) begin
            refresh_counter <= '0;
        end else begin
            refresh_counter <= refresh_counter+1;
        end
    end

    always_comb begin
        enable = '1;
        enable[enable_select] = 1'b0;
        bcd = packed_bcd_reg[16-(4*enable_select)-1-:4];

        if (HEX == 0) begin
            case (bcd)
                0:       led_out = 8'b00000011; // 0x03
                1:       led_out = 8'b10011111; // 0x9F
                2:       led_out = 8'b00100101; // 0x25
                3:       led_out = 8'b00001101; // 0x0D
                4:       led_out = 8'b10011001; // 0x99
                5:       led_out = 8'b01001001; // 0x49
                6:       led_out = 8'b01000001; // 0x41
                7:       led_out = 8'b00011111; // 0x1F
                8:       led_out = 8'b00000001; // 0x01
                9:       led_out = 8'b00001001; // 0x09
                default: led_out = '1;
            endcase
        end else begin
            case (data_in)
                0:       led_out = 8'b0000_0011;
                1:       led_out = 8'b1001_1111;
                2:       led_out = 8'b0010_0101;
                3:       led_out = 8'b0000_1101;
                4:       led_out = 8'b1001_1001;
                5:       led_out = 8'b0100_1001;
                6:       led_out = 8'b0100_0001;
                7:       led_out = 8'b0001_1111;
                8:       led_out = 8'b0000_0001;
                9:       led_out = 8'b0000_1001;
                10:      led_out = 8'b0001_0001;
                11:      led_out = 8'b1100_0001;
                12:      led_out = 8'b0110_0011;
                13:      led_out = 8'b1000_0101;
                14:      led_out = 8'b0110_0001;
                15:      led_out = 8'b0111_0001;
                default: led_out = '1;
            endcase
        end
    end

   initial begin
       $dumpfile("seven_segment_display.vcd");
       $dumpvars();
   end

endmodule


