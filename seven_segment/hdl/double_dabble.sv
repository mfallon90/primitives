`timescale 1ns / 1ps

module double_dabble #(
    parameter NUM_BITS = 14
) (
    input  wire                 clk,
    input  wire                 reset,
    input  wire  [NUM_BITS-1:0] binary_in,
    input  wire                 binary_in_valid,
    output logic [15:0]         packed_bcd_out,
    output logic                packed_bcd_out_valid
);

    typedef enum {
        IDLE,
        SHIFT,
        CHECK_LP,
        ADD,
        DONE
    } state_t;

    state_t                          state;
    logic     [NUM_BITS-1:0]         bin;
    logic     [$clog2(NUM_BITS)-1:0] count;
    logic     [15:0]                 pckd_bcd;

    assign packed_bcd_out = pckd_bcd;
    
    always_ff @(posedge clk) begin
        if(reset == 1) begin
            state                <= IDLE;
            packed_bcd_out_valid <= '0;
            bin                  <= 'x;
            count                <= 'x;
            pckd_bcd             <= 'x;
        end else begin
            packed_bcd_out_valid <= '0;
            case(state)
                IDLE: begin
                    state    <= IDLE;
                    pckd_bcd <= 0;
                    count    <= 0;
                    bin      <= binary_in;

                    if(binary_in_valid == 1) begin
                        state <= SHIFT;
                    end
                end

                SHIFT: begin
                    state       <=  CHECK_LP;
                    pckd_bcd    <= {pckd_bcd[14:0], bin[NUM_BITS-1]};
                    bin         <=  bin << 1;
                    count       <=  count + 1;
                end

                CHECK_LP: begin
                    state <= ADD;

                    if(count >= NUM_BITS) begin
                        state <= DONE;
                    end
                end

                ADD: begin
                    state <= SHIFT;
                    if (pckd_bcd[15:12]>4) begin pckd_bcd[15:12] <= pckd_bcd[15:12]+3; end
                    if (pckd_bcd[11:8]>4)  begin pckd_bcd[11:8]  <= pckd_bcd[11:8]+3;  end
                    if (pckd_bcd[7:4]>4)   begin pckd_bcd[7:4]   <= pckd_bcd[7:4]+3;   end
                    if (pckd_bcd[3:0]>4)   begin pckd_bcd[3:0]   <= pckd_bcd[3:0]+3;   end
                end

                DONE: begin
                    state                <= IDLE;
                    packed_bcd_out_valid <= 1'b1;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
