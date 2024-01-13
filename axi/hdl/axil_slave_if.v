
`timescale 1 ns / 1 ps
`define NUM_REG (P_NUM_RW_REG + P_NUM_RO_REG)

module axil_slave_if #(
    parameter integer P_DATA_WIDTH  = 32,
    parameter integer P_NUM_RW_REG  = 2,
    parameter integer P_NUM_RO_REG  = 2,
    parameter integer P_ADDR_WIDTH  = ($clog2(`NUM_REG) + 2)
    )(
    // Clock and reset
    input   wire                            s_axi_aclk,
    input   wire                            s_axi_aresetn,
    // Write address channel
    input   wire    [P_ADDR_WIDTH-1:0]      s_axi_awaddr,
    input   wire    [2:0]                   s_axi_awprot,
    input   wire                            s_axi_awvalid,
    output  wire                            s_axi_awready,
    // Write data channel
    input   wire    [P_DATA_WIDTH-1:0]      s_axi_wdata,
    input   wire    [(P_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
    input   wire                            s_axi_wvalid,
    output  wire                            s_axi_wready,
    // Write response channel
    output  wire    [1:0]                   s_axi_bresp,
    output  wire                            s_axi_bvalid,
    input   wire                            s_axi_bready,
    // Read address channel
    input   wire    [P_ADDR_WIDTH-1:0]      s_axi_araddr,
    input   wire    [2:0]                   s_axi_arprot,
    input   wire                            s_axi_arvalid,
    output  wire                            s_axi_arready,
    // Read data channel
    output  wire    [P_DATA_WIDTH-1:0]      s_axi_rdata,
    output  wire    [1:0]                   s_axi_rresp,
    output  wire                            s_axi_rvalid,
    input   wire                            s_axi_rready,
    // PL data
    output  wire    [P_DATA_WIDTH-1:0]      reg_0_data,
    output  wire    [P_DATA_WIDTH-1:0]      reg_1_data,
    input   wire    [P_DATA_WIDTH-1:0]      reg_2_data,
    input   wire    [P_DATA_WIDTH-1:0]      reg_3_data
    );

    localparam  [1:0]   C_OKAY      = 2'b00;
    localparam  [1:0]   C_EX_OKAY   = 2'b01;
    localparam  [1:0]   C_SLV_ERR   = 2'b10;
    localparam  [1:0]   C_DEC_ERR   = 2'b11;

    // Register addresses - not byte addressable
    localparam  integer RED_0_ADDR  = 0;
    localparam  integer RED_1_ADDR  = 1;
    localparam  integer RED_2_ADDR  = 2;
    localparam  integer RED_3_ADDR  = 3;

    // Read/Write registers
    reg     [P_DATA_WIDTH-1:0]  reg_0;
    reg     [P_DATA_WIDTH-1:0]  reg_1;

    // Read only registers
    wire    [P_DATA_WIDTH-1:0]  reg_2;
    wire    [P_DATA_WIDTH-1:0]  reg_3;

    reg [P_ADDR_WIDTH-1:0]  i;
    reg [P_ADDR_WIDTH-1:0]  read_address;
    reg [P_ADDR_WIDTH-1:0]  write_address;
    reg [P_DATA_WIDTH-1:0]  read_data;
    reg [P_DATA_WIDTH-1:0]  write_data;
    reg [1:0]               read_resp;
    reg [1:0]               write_resp;
    reg                     rd_addr_rdy;
    reg                     rd_data_vld;
    reg                     wr_addr_rdy;
    reg                     wr_data_rdy;
    reg                     write_valid;
    reg                     rd_en;
    reg                     wr_addr_good;
    reg                     wr_data_good;

    assign s_axi_awready    = wr_addr_rdy;
    assign s_axi_wready     = wr_data_rdy;
    assign s_axi_bresp      = write_resp;
    assign s_axi_bvalid     = write_valid;
    assign s_axi_arready    = rd_addr_rdy;
    assign s_axi_rdata      = read_data;
    assign s_axi_rresp      = read_resp;
    assign s_axi_rvalid     = rd_data_vld;

    assign reg_0_data   = reg_0;
    assign reg_1_data   = reg_1;
    assign reg_2        = reg_2_data;
    assign reg_3        = reg_3_data;

    // Read process
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            rd_addr_rdy     <= 1'b0;
            read_address    <= 0;
            read_data       <= 0;
            read_resp       <= 0;
            rd_data_vld     <= 1'b0;
            rd_en           <= 1'b0;
        end

        else begin
            // Latch read address
            if (s_axi_arvalid & ~rd_addr_rdy) begin
                rd_addr_rdy     <= 1'b1;
                read_address    <= s_axi_araddr;
                rd_en           <= 1'b1;
            end
            else begin
                rd_addr_rdy     <= 1'b0;
            end

            // Output read data
            if (rd_en) begin
                    read_resp   <= C_OKAY;
                    rd_data_vld <= 1'b1;
                    rd_en       <= 1'b0;
                // Drop the two LSB's due to not being
                // byte addressable
                case (read_address[P_ADDR_WIDTH-1:2])
                    RED_0_ADDR: read_data   <= reg_0;
                    RED_1_ADDR: read_data   <= reg_1;
                    RED_2_ADDR: read_data   <= reg_2;
                    RED_3_ADDR: read_data   <= reg_3;
                endcase
            end
            else begin
                if (s_axi_rready & rd_data_vld) begin
                    read_data   <= 0;
                    rd_data_vld <= 1'b0;
                end
            end
        end
    end


    // Write process
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            wr_addr_rdy     <= 1'b0;
            write_address   <= 0;
            wr_data_rdy     <= 1'b0;
            write_data      <= 0;
            write_resp      <= 0;
            write_valid     <= 1'b0;
            wr_data_good    <= 1'b0;
            wr_addr_good    <= 1'b0;
            reg_0           <= 0;
            reg_1           <= 0;
        end

        else begin
            // Latch write address
            if (s_axi_awvalid & ~wr_addr_rdy & ~wr_addr_good) begin
                wr_addr_rdy     <= 1'b1;
                write_address   <= s_axi_awaddr;
                wr_addr_good    <= 1'b1;
            end
            else begin
                wr_addr_rdy     <= 1'b0;
            end

            // Latch write data
            if (s_axi_wvalid & ~wr_data_rdy & ~wr_data_good) begin
                wr_data_rdy     <= 1'b1;
                write_data      <= s_axi_wdata;
                wr_data_good    <= 1'b1;
            end
            else begin
                wr_data_rdy     <= 1'b0;
            end

            // Write write data to register
            if (wr_data_good & wr_addr_good) begin
                write_resp      <= C_OKAY;
                write_valid     <= 1'b1;
                wr_data_good    <= 1'b0;
                wr_addr_good    <= 1'b0;
                // Drop the two LSB's due to not being
                // byte addressable
                case (write_address[P_ADDR_WIDTH-1:2])
                    RED_0_ADDR: reg_0   <= write_data;
                    RED_1_ADDR: reg_1   <= write_data;
                endcase
            end
            else if (write_valid & s_axi_bready) begin
                write_valid <= 1'b0;
            end
        end
    end


    // Dump waves
    initial begin
        $dumpfile("axil_slave_if.vcd");
        $dumpvars;
    end


    endmodule
