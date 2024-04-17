/*
 * Copyright (c) 2023 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_fstolzcode (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire reset = ~rst_n;
assign uo_out[0] = 0;
assign uo_out[1] = 0;
assign uo_out[2] = 0;
assign uo_out[3] = 0;
assign uo_out[5] = 0;
assign uo_out[6] = 0;
assign uo_out[7] = 0;
assign uio_out = 0;
assign uio_oe  = 0;


// Clock frequency in hertz.
parameter CLK_HZ = 10000000;
parameter BIT_RATE =   9600;
parameter PAYLOAD_BITS = 8;

wire [PAYLOAD_BITS-1:0]  uart_rx_data;
wire        uart_rx_valid;

wire       uart_tx_busy;
reg        uart_tx_en;
reg [7:0]  uart_tx_data;


// UART RX
uart_rx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk ), // Top level system clock input.
.resetn       (rst_n         ), // Asynchronous active low reset.
.uart_rxd     (ui_in[3]), // UART Recieve pin.
.uart_rx_en   (1'b1         ), // Recieve enable
.uart_rx_break(), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data)  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_tx(
.clk          (clk ),
.resetn       (rst_n         ),
.uart_txd     (uo_out[4]),
.uart_tx_en   (uart_tx_en   ),
.uart_tx_busy (uart_tx_busy ),
.uart_tx_data (uart_tx_data ) 
);


reg r1s;
reg [6:0] r1e;
reg [14:0] r1m;
reg r2s;
reg [6:0] r2e;
reg [14:0] r2m;
wire rss;
wire [6:0] rse;
wire [14:0] rsm;

localparam CTRL_SIZE = 4;
localparam CTRL_IDLE  = 4'd0,CTRL_SETR1 = 4'd1,CTRL_SETR2 = 4'd2,CTRL_READR1 = 4'd3,CTRL_READR2 = 4'd4,CTRL_READRS = 4'd5,CTRL_ADD=4'd6,CTRL_SUB=4'd7,CTRL_WAIT1=4'd8,
CTRL_READSTAT=4'd9, CTRL_MUL=4'd10, CTRL_DIV=4'd11, CTRL_SQRT=4'd12, CTRL_WAIT2 = 4'd13;

reg   [CTRL_SIZE-1:0]          state        ;// Seq part of the FSM
reg [2:0] cnt;
reg add;
reg sub;
reg mul;
reg div;
reg sqrt;

wire fpu_idle;
wire [2:0] flags;
fpu fpu_inst(
    .clk(clk),
    .reset(reset),
    .add(add),
    .sub(sub),
    .mul(mul),
    .div(div),
    .sqrt(sqrt),
    .reg1_s(r1s),
    .reg1_e(r1e),
    .reg1_m(r1m),
    .reg2_s(r2s),
    .reg2_e(r2e),
    .reg2_m(r2m),
    .res_s(rss),
    .res_e(rse),
    .res_m(rsm),
    .zero_flag(flags[0]),
    .overflow_flag(flags[1]),
    .underflow_flag(flags[2]),
    .idle(fpu_idle)
);

always @ (posedge clk)
begin : OUTPUT_LOGIC
  if(reset == 1'b1) begin
    r1s <= 0;
    r1e <= 0;
    r1m <= 0;
    r2s <= 0;
    r2e <= 0;
    r2m <= 0;
    uart_tx_en <= 0;
    uart_tx_data <= 0;
    cnt <= 0;
    add <= 0;
    sub <= 0;
    mul <= 0;
    div <= 0;
    sqrt <= 0;
    state <= CTRL_IDLE;
  end else begin
      case(state)
      CTRL_IDLE : begin
            uart_tx_en <= 0;
            uart_tx_data <= 0;
            cnt <= 0;
            add <= 0;
            sub <= 0;
            mul <= 0;
            div <= 0;
            sqrt <= 0;
            if(uart_rx_valid == 1'b1) begin
                case(uart_rx_data)
                    8'b10000010: state <= CTRL_SETR1;
                    8'b10000011: state <= CTRL_SETR2;
                    8'b10000100: state <= CTRL_READSTAT;
                    8'b10000101: state <= CTRL_READR1;
                    8'b10000110: state <= CTRL_READR2;
                    8'b10000111: state <= CTRL_READRS;
                    8'b10001000: state <= CTRL_ADD;
                    8'b10001001: state <= CTRL_SUB;
                    8'b10001010: state <= CTRL_MUL;
                    8'b10001011: state <= CTRL_DIV;
                    8'b10001100: state <= CTRL_SQRT;
                    default: state <= CTRL_IDLE;
                endcase
            end
      end
      CTRL_READSTAT: begin
            if(uart_tx_busy == 1'b1) begin
                uart_tx_en <= 0;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd0) begin
                uart_tx_data <= {5'b0,flags};
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd1) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_SETR1: begin
            if(uart_rx_valid && cnt == 3'd0) begin
                r1s <= uart_rx_data[7];
                r1e <= uart_rx_data[6:0];
                cnt <= cnt + 1'b1;
            end else if (uart_rx_valid && cnt == 3'd1) begin
                r1m[14:7] <= uart_rx_data;
                cnt <= cnt + 1'b1;
            end else if (uart_rx_valid && cnt == 3'd2) begin
                r1m[6:0] <= uart_rx_data[7:1];
                state <= CTRL_IDLE;
            end
      end
      CTRL_SETR2: begin
            if(uart_rx_valid && cnt == 3'd0) begin
                r2s <= uart_rx_data[7];
                r2e <= uart_rx_data[6:0];
                cnt <= cnt + 1'b1;
            end else if (uart_rx_valid && cnt == 3'd1) begin
                r2m[14:7] <= uart_rx_data;
                cnt <= cnt + 1'b1;
            end else if (uart_rx_valid && cnt == 3'd2) begin
                r2m[6:0] <= uart_rx_data[7:1];
                state <= CTRL_IDLE;
            end
      end
      CTRL_READR1: begin
            if(uart_tx_busy == 1'b1) begin
                uart_tx_en <= 0;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd0) begin
                 uart_tx_data <= {r1s,r1e};
                 uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd1) begin
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd2) begin
                uart_tx_data <= r1m[14:7];
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd3) begin
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd4) begin
                uart_tx_data <= {r1m[6:0],1'b0};
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd5) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_READR2: begin
             if(uart_tx_busy == 1'b1) begin
                uart_tx_en <= 0;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd0) begin
                 uart_tx_data <= {r2s,r2e};
                 uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd1) begin
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd2) begin
                uart_tx_data <= r2m[14:7];
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd3) begin
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd4) begin
                uart_tx_data <= {r2m[6:0],1'b0};
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd5) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_READRS: begin
            if(uart_tx_busy == 1'b1) begin
                uart_tx_en <= 0;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd0) begin
                uart_tx_data <= {rss,rse};
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd1) begin
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd2) begin
                uart_tx_data <= rsm[14:7];
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd3) begin
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd4) begin
                uart_tx_data <= {rsm[6:0],1'b0};
                uart_tx_en <= 1;
                cnt <= cnt + 1'b1;
            end else if(uart_tx_busy == 1'b0 && cnt == 3'd5) begin
                state <= CTRL_IDLE;
            end
      end
      CTRL_ADD: begin
        add <= 1;
        state <= CTRL_WAIT1;
      end
      CTRL_SUB: begin
        sub <= 1;
        state <= CTRL_WAIT1;
      end
      CTRL_MUL: begin
        mul <= 1;
        state <= CTRL_WAIT1;
      end
      CTRL_DIV: begin
        div <= 1;
        state <= CTRL_WAIT1;
      end
      CTRL_SQRT: begin
        sqrt <= 1;
        state <= CTRL_WAIT1;
      end
      CTRL_WAIT1: begin
        mul <= 0;
        add <= 0;
        sub <= 0;
        div <= 0;
        sqrt <= 0;
        state <= CTRL_WAIT2;
      end
      CTRL_WAIT2: begin
        if(fpu_idle == 1'b1) begin
            state <= CTRL_IDLE;
        end
      end
      default: begin
        state <= CTRL_IDLE;
      end
   endcase
  end
end
endmodule