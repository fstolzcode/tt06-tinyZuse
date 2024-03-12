/*
 * Copyright (c) 2023 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

assign uo_out[0] = 0;
assign uo_out[1] = 0;
assign uo_out[2] = 0;
assign uo_out[3] = 0;
assign uo_out[5] = 0;
assign uo_out[6] = 0;
assign uo_out[7] = 0;
assign uio_out = 0;
assign uio_oe  = 0;

wire clk_10MHZ;
assign clk_10MHZ = clk;

wire [7:0] rx_data;
wire rx_valid;
uart_rx #(
  .CLK_HZ( 10000000 ),  // in Hertz
  .BAUD( 9600 )            // max. BAUD is CLK_HZ / 2
) uart_rx_ins(
  .clk(clk_10MHZ),
  .nrst(rst_n),

  .rx_data(rx_data),
  .rx_done(rx_valid),
  .rxd(ui_in[3])
);

reg [7:0] tx_data;
reg tx_en;
wire tx_busy;
uart_tx #(
  .CLK_HZ( 10000000 ),  // in Hertz
  .BAUD( 9600 )            // max. BAUD is CLK_HZ / 2
) tx1 (
  .clk(clk_10MHZ),
  .nrst(rst_n),
  //.tx_do_sample(  ),
  .tx_data(tx_data),
  .tx_start(tx_en),
  .tx_busy(tx_busy),
  .txd(uo_out[4])
);

localparam CTRL_SIZE = 4;
localparam CTRL_IDLE  = 4'd0,CTRL_SETR1 = 4'd1,CTRL_SETR2 = 4'd2,CTRL_READR1 = 4'd3,CTRL_READR2 = 4'd4,CTRL_READRS = 4'd5,CTRL_ADD=4'd6;

reg   [CTRL_SIZE-1:0]          state        ;// Seq part of the FSM
reg   [CTRL_SIZE-1:0]          next_state   ;// combo part of FSM

reg [6:0] r1e;
reg [14:0] r1m;
reg [6:0] r2e;
reg [14:0] r2m;
wire [6:0] rse;
wire [14:0] rsm;
reg add;
wire alu_idle;
reg [3:0] cnt;

fpu fpu_inst(
    .clk(clk_10MHZ),
    .reset(~rst_n),
    .add(add),
    .reg1_e(r1e),
    .reg1_m(r1m),
    .reg2_e(r2e),
    .reg2_m(r2m),
    .res_e(rse),
    .res_m(rsm),
    .idle(alu_idle)
    );

always @ (posedge clk_10MHZ)
begin : OUTPUT_LOGIC
  if(rst_n == 1'b0) begin
    state <= CTRL_IDLE;
  end else begin
      case(state)
      CTRL_IDLE : begin
            tx_en <= 0;   
            cnt <= 0;
            add <= 0;
            if(rx_valid == 1'b1) begin
                case(rx_data)
                    8'b10000001: state <= CTRL_SETR1;
                    8'b10000010: state <= CTRL_SETR2;
                    8'b10000011: state <= CTRL_READR1;
                    8'b10000100: state <= CTRL_READR2;
                    8'b10000101: state <= CTRL_READRS;
                    8'b10001001: state <= CTRL_ADD;
                    default: state <= CTRL_IDLE;
                endcase
            end
      end
      CTRL_SETR1: begin
            if(rx_valid && cnt == 4'd0) begin
                r1e <= rx_data[6:0];
                cnt <= cnt + 1'b1;
            end else if (rx_valid && cnt == 4'd1) begin
                r1m[14:7] <= rx_data;
                cnt <= cnt + 1'b1;
            end else if (rx_valid && cnt == 4'd2) begin
                r1m[6:0] <= rx_data[7:1];
                state <= CTRL_IDLE;
            end
      end
      CTRL_SETR2: begin
            if(rx_valid && cnt == 4'd0) begin
                r2e <= rx_data[6:0];
                cnt <= cnt + 1'b1;
            end else if (rx_valid && cnt == 4'd1) begin
                r2m[14:7] <= rx_data;
                cnt <= cnt + 1'b1;
            end else if (rx_valid && cnt == 4'd2) begin
                r2m[6:0] <= rx_data[7:1];
                state <= CTRL_IDLE;
            end
      end
      CTRL_READR1: begin
            if(tx_busy == 1'b1) begin
                tx_en <= 0;
            end else if(tx_busy == 1'b0 && cnt == 4'd0) begin
                tx_data <= {1'b0,r1e};
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd1) begin
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd2) begin
                tx_data <= r1m[14:7];
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd3) begin
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd4) begin
                tx_data <= {r1m[6:0],1'b0};
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd5) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_READR2: begin
            if(tx_busy == 1'b1) begin
                tx_en <= 0;
            end else if(tx_busy == 1'b0 && cnt == 4'd0) begin
                tx_data <= {1'b0,r2e};
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd1) begin
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd2) begin
                tx_data <= r2m[14:7];
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd3) begin
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd4) begin
                tx_data <= {r2m[6:0],1'b0};
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd5) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_READRS: begin
            if(tx_busy == 1'b1) begin
                tx_en <= 0;
            end else if(tx_busy == 1'b0 && cnt == 4'd0) begin
                tx_data <= {1'b0,rse};
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd1) begin
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd2) begin
                tx_data <= rsm[14:7];
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd3) begin
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd4) begin
                tx_data <= {rsm[6:0],1'b0};
                tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(tx_busy == 1'b0 && cnt == 4'd5) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_ADD: begin
        add <= 1;
        state <= CTRL_IDLE;
      end
      default: begin
        state <= CTRL_IDLE;
      end
   endcase
  end
end
endmodule