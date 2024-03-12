`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/06/2024 07:50:50 PM
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fpu(
    input wire clk,
    input wire reset,
    input wire add,
    input wire sub,
    input [6:0] reg1_e,
    input [14:0] reg1_m,
    input [6:0] reg2_e,
    input [14:0] reg2_m,
    output reg [6:0] res_e,
    output reg [14:0] res_m,
    output reg idle
    );

localparam SIZE = 4           ;
localparam ALU_IDLE  = 4'd0,
ADD0 = 4'd1,ADD1 = 4'd2,ADD2 = 4'd3,ADD3 = 4'd4,ADD4 = 4'd5,
SUB0 = 4'd6, SUB1=4'd7, SUB2=4'd8, SUB3 = 4'd9, SUB4=4'd10, SUB5=4'd11;

reg   [SIZE-1:0]          state        ;// Seq part of the FSM

reg [6:0] af;
reg [14:0] bf;
reg [7:0] aa;
reg [16:0] ba; // two front 
reg [7:0] ab;
reg [15:0] bb; // one front 
wire signed [7:0] ae;
wire [15:0] be; // one front

reg alu_a_c_in;
reg alu_a_c_out;
alu_a alu_a_inst(aa,ab,alu_a_c_in,ae,reg_alu_c_out);

reg [15:0] bb_shift_in;
reg [4:0] bb_shift_amount;
reg bb_left;
reg [15:0] bb_shift_out;
bb_shifter bb_shift_ins(bb_shift_in,bb_shift_amount,bb_left,bb_shift_out);

reg alu_b_c_in;
reg alu_b_c_out;
alu_b alu_b_inst(ba,bb,alu_b_c_in,be,alu_b_cout);

always @ (posedge clk)
begin : OUTPUT_LOGIC
  if(reset == 1'b1) begin
    state <= ALU_IDLE;
  end else begin
      case(state)
      ALU_IDLE: begin
          af <= 0;
          bf <= 0;
          aa <= 0;
          ba <= 0;
          ab <= 0;
          bb <= 0;
          alu_a_c_in <= 0;
          alu_b_c_in <= 0;
          bb_shift_in <= 0;
          bb_shift_amount <= 0;
          bb_left <= 0;
          idle <= 1;
          if(add == 1'b1) begin
            state <= ADD0;
          end else if (sub == 1'b1) begin
            state <= SUB0;
          end
      end
      ADD0 : begin
          idle <= 0;
          aa <= {reg1_e[6],reg1_e[6:0]};
          af <= reg1_e;     
          ab <= {~reg2_e[6],~(reg2_e[6:0])};
          bf <= reg1_m;
          bb <= {1'b0,reg2_m};
          alu_a_c_in <= 1;
          state <= ADD1;
          end
        ADD1 : begin
          if(ae >= 0) begin
            ab <= 0;
            aa <= {af[6],af[6:0]};
            ba <= {2'b0,bf};
            bb_shift_in <= be;
            bb_left <= 0;
            bb_shift_amount <= {8'b0,ae};
          end else begin
            aa <= 0;
            ab <= ~ab;
            ba <= {1'b0,be};
            bb_shift_in <= {1'b0,bf};
            bb_left <= 0;
            bb_shift_amount <= {8'b0,-ae};
          end
           state <= ADD2;
        end
        ADD2 : begin
            bb <= bb_shift_out;
            state <= ADD3;
        end
        ADD3 : begin
            if(be[15] == 1'b1) begin
            bb_shift_in <= be;
            bb_shift_amount <= 1;
            bb_left <= 0;
            alu_a_c_in <= 1;
            end else begin
            bb_shift_in <= be;
            bb_shift_amount <= 0;
            bb_left <= 0;
            alu_a_c_in <= 0;
            end
             state <= ADD4;
        end
        ADD4: begin
            res_e <= ae[6:0];
            res_m <= bb_shift_out;
            state <= ALU_IDLE;
        end
        // SUB
        SUB0: begin
          aa <= reg1_e;
          af <= reg1_e;     
          ab <= ~reg2_e;
          bf <= reg1_m;
          bb <= {1'b0,reg2_m};
          alu_a_c_in <= 1;
          state <= SUB1;
        end
        SUB1: begin
            if(ae >= 0) begin
            ab <= 0;
            aa <= af;
            ba <= {2'b0,bf};
            bb_shift_in <= be;
            bb_left <= 0;
            bb_shift_amount <= {8'b0,ae};
          end else begin
            aa <= 0;
            ab <= ~ab;
            ba <= {1'b0,be};
            bb_shift_in <= {1'b0,bf};
            bb_left <= 0;
            bb_shift_amount <= {8'b0,-ae};
          end
          alu_a_c_in <= 0;
          state <= SUB2;
        end
        SUB2: begin
            bb <= ~bb_shift_out;
            alu_b_c_in <= 1;
            state <= SUB3;
        end
        SUB3: begin
           aa <= ae;
           ab <= 0;
           ba <= 0;
           if (be[15] == 1'b0) begin
              bb <= be;
              alu_b_c_in <= 0;
           end else begin
                //assert(1 == 0);
                bb <= ~be;
                alu_b_c_in <= 1;
           end
           state <= SUB4;
        end
        SUB4: begin
           aa <= ae;
           bb_shift_in <= be;
           bb_left <= 1;
           if(be[14] == 1'b1) begin
           ab <= ~8'b0;
           bb_shift_amount <= 0;
           end else begin
                if(be[13] == 1'b1) begin
                ab <= ~8'd1;
                bb_shift_amount <= 5'd1;
                end else if(be[12] == 1'b1) begin
                ab <= ~8'd2;
                bb_shift_amount <= 5'd2;
                end else if(be[11] == 1'b1) begin
                ab <= ~8'd3;
                bb_shift_amount <= 5'd3;
                end else if(be[10] == 1'b1) begin
                ab <= ~8'd4;
                bb_shift_amount <= 5'd4;
                end else if(be[9] == 1'b1) begin
                ab <= ~8'd5;
                bb_shift_amount <= 5'd5;
                end else if(be[8] == 1'b1) begin
                ab <= ~8'd6;
                bb_shift_amount <= 5'd6;
                end else if(be[7] == 1'b1) begin
                ab <= ~8'd7;
                bb_shift_amount <= 5'd7;
                end else if(be[6] == 1'b1) begin
                ab <= ~8'd8;
                bb_shift_amount <= 5'd8;
                end else if(be[5] == 1'b1) begin
                ab <= ~8'd9;
                bb_shift_amount <= 5'd9;
                end else if(be[4] == 1'b1) begin
                ab <= ~8'd10;
                bb_shift_amount <= 5'd10;
                end else if(be[3] == 1'b1) begin
                ab <= ~8'd11;
                bb_shift_amount <= 5'd11;
                end else if(be[2] == 1'b1) begin
                ab <= ~8'd12;
                bb_shift_amount <= 5'd12;
                end else if(be[1] == 1'b1) begin
                ab <= ~8'd13;
                bb_shift_amount <= 5'd13;
                end else if(be[0] == 1'b1) begin
                ab <= ~8'd14;
                bb_shift_amount <= 5'd14;
                end
           end
            alu_a_c_in <= 1;
            state <= SUB5;
        end
        SUB5: begin
        res_e <= ae;
        res_m <= bb_shift_out[14:0];
        state <= ALU_IDLE;
        end
      default: begin
        state <= ALU_IDLE;
      end
   endcase
  end
end

endmodule