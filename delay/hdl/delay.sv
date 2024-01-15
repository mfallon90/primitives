`timescale 1ns / 1ps

module delay #(
    parameter int NUM_CYCLES     = 6,
    parameter int WIDTH          = 14,
    parameter bit RESET          = 0,
    parameter bit RESET_POLARITY = 0
    )(
    input  wire                 clk,
    input  wire                 reset,
    input  wire  [WIDTH-1:0]    data_in,
    output logic [WIDTH-1:0]    data_out
    );

    generate
        if (NUM_CYCLES == 0) begin
            assign data_out = data_in;
        end
        else begin
            logic [NUM_CYCLES-1:0][WIDTH-1:0] data_reg;
            assign data_out               = data_reg[0];

            if (RESET == 1) begin
                always_ff @(posedge clk) begin
                    if (reset == RESET_POLARITY) begin
                        for (int i=0; i<NUM_CYCLES; i=i+1) begin
                            data_reg[i] <= '0;
                        end
                    end else begin
                        data_reg[NUM_CYCLES-1] <= data_in;
                        for (int i=0; i<NUM_CYCLES-1; i=i+1) begin
                            data_reg[i] <= data_reg[i+1];
                        end
                    end
                end
            end else begin
                always_ff @(posedge clk) begin
                    data_reg[NUM_CYCLES-1] <= data_in;
                    for (int i=0; i<NUM_CYCLES-1; i=i+1) begin
                        data_reg[i] <= data_reg[i+1];
                    end
                end
            end
        end
    endgenerate

    initial begin
        $dumpfile("delay.vcd");
        $dumpvars();
    end
endmodule
