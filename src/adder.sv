`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2024 06:21:56 PM
// Design Name: 
// Module Name: fpu_new
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


parameter SIZE = 5;
parameter ALU_IDLE  = 5'd0,
ADD0 = 5'd1, ADD1 = 5'd2,ADD2 = 5'd3,ADD3 = 5'd4,ADD4 = 5'd5,
ADD5 = 5'd6, ADD6= 5'd7, ADD7=5'd8, ADD8 = 5'd9, ADD9=5'd10, ADD10=5'd11, ADD11=5'd12, ADD12=5'd13, ADD13=5'd14, 
SUB0=5'd15, SUB1= 5'd16, SUB2=5'd17, SUB3= 5'd18, SUB4=5'd19, SUB5= 5'd20, SUB6=5'd21, SUB7= 5'd22, SUB8=5'd23, SUB9= 5'd24,
SUB10=5'd25;

reg   [SIZE-1:0]          state        ;// Seq part of the FSM

reg[16:0] sa_in;
reg[16:0] sb_in;
reg sc_in;
reg sadder_en;
wire sadder_done;
wire[16:0] sadder_out;
wire sadder_cout;

serial_adder sa(
    .clk(clk),
    .reset(reset),
    .en(sadder_en),
    .a(sa_in),
    .b(sb_in),
    .c_in(sc_in),
    .done(sadder_done),
    .out(sadder_out),
    .c_out(sadder_cout)
);

reg sshifter_en;
reg sshifter_left;
wire sshifter_done;
wire[16:0] sshifter_out;
serial_shifter sh(
    .clk(clk),
    .reset(reset),
    .en(sshifter_en),
    .left(sshifter_left),
    .a(sa_in),
    .amount(sb_in[4:0]),
    .done(sshifter_done),
    .out(sshifter_out)
);

reg[7:0] aa;
reg[7:0] ab;
reg[7:0] ae;

reg[16:0] ba;
reg[16:0] bb;
reg[16:0] be;

reg[3:0] temp;
reg operation;

always @ (posedge clk)
begin : OUTPUT_LOGIC
  if(reset == 1'b1) begin
    state <= ALU_IDLE;
  end else begin
      case(state)
      ALU_IDLE: begin
          idle <= 1;
          
          sadder_en <= 0;
          sa_in <= 0;
          sb_in <= 0;
          sc_in <= 0;
          
          sshifter_en <= 0;
          sshifter_left <= 0;
          
          aa <= 0;
          ab <= 0;
          ae <= 0;
          
          ba <= 0;
          bb <= 0;
          be <= 0;
          
          temp <= 0;
          
          if(add == 1'b1) begin
            state <= ADD0;
            operation <= 0;
          end else if (sub == 1'b1) begin
            state <= ADD0;
            operation <= 1;
          end
      end
      ADD0 : begin
          idle <= 0;
          sa_in <= { {10{reg1_e[6]}} , reg1_e};
          sb_in <= { {10{~reg2_e[6]}} , ~reg2_e};
          sc_in <= 1;
          sadder_en <= 1;
          state <= ADD1;
          end
       ADD1 : begin
         if(sadder_done == 1'b0) begin
            state <= ADD2;
         end
         end
       ADD2 : begin
          sadder_en <= 0;
          if(sadder_done == 1'b1) begin
            ae <= sadder_out[7:0];
            state <= ADD3;
          end
          end
       ADD3: begin
            if(ae[7] == 1'b0) begin
                ab <= 0;
                aa <= {reg1_e[6] ,reg1_e};
                
                ba <= {2'b0,reg1_m};
                sa_in <= {2'b0,reg2_m};
                sb_in <= {9'b0, ae};
                sshifter_left <= 0;
                sshifter_en <= 1;
                state <= ADD4;
            end else begin
                aa <= 0;
                ab <= {reg2_e[6] ,reg2_e};
                
                ba <= {2'b0,reg2_m};
                sa_in <= { {9{~ae[7]}}, ~ae};
                sb_in <= 17'b1;
                sc_in <= 1'b0;
                sadder_en <= 1;
                state <= ADD12;
            end
       end
       ADD4 : begin
         if(sshifter_done == 1'b0) begin
            state <= ADD5;
         end
         end
       ADD5 : begin
          sshifter_en <= 0;
          if(sshifter_done == 1'b1 && operation == 1'b0) begin
            bb <= sshifter_out;
            state <= ADD6;
          end else if(sshifter_done == 1'b1 && operation == 1'b1) begin
            bb <= sshifter_out;
            state <= SUB0;
          end
          end
       ADD6: begin
          sa_in <= ba;
          sb_in <= bb;
          sc_in <= 0;
          sadder_en <= 1;
          state <= ADD7;
       end
       ADD7 : begin
         if(sadder_done == 1'b0) begin
            state <= ADD8;
         end
         end
        ADD8 : begin
          sadder_en <= 0;
          if(sadder_done == 1'b1) begin
            be <= sadder_out;
            state <= ADD9;
          end
          end
         ADD9: begin
            if( (be[16] | be[15]) == 1'b1) begin
               sa_in <= {9'b0, aa};
               sb_in <= {9'b0, ab};
               sc_in <= 1;
               sadder_en <= 1;
               state <= ADD10;
            end else begin
               res_e <= aa[6:0] | ab[6:0];
               res_m <= be[14:0];
               state <= ALU_IDLE;
            end
         end
         ADD10: begin
            if(sadder_done == 1'b0) begin
            state <= ADD11;
            end
         end
         ADD11: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1) begin
             res_e <= sadder_out[6:0];
             res_m <= be[15:1];
             state <= ALU_IDLE;
          end
         end
         ADD12: begin
            if(sadder_done == 1'b0) begin
            state <= ADD13;
            end
         end
         ADD13: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1) begin
                sa_in <= {2'b0,reg1_m};
                sb_in <= sadder_out;
                sshifter_left <= 0;
                sshifter_en <= 1;
                state <= ADD4;
            end
         end
         ////////////// SUB
         SUB0: begin
            sa_in <= ba;
            sb_in <= ~bb;
            sc_in <= 1;
            sadder_en <= 1;
            state <= SUB1;
         end
         SUB1: begin
            if(sadder_done == 1'b0) begin
            state <= SUB2;
            end
         end
         SUB2: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1 && sadder_out[16] == 1'b1) begin
                //NEGATIVE
                sa_in <= ~sadder_out;
                sb_in <= 17'b1;
                sc_in <= 0;
                sadder_en <= 1;
                state <= SUB3;
            end else if(sadder_done == 1'b1 && sadder_out[16] == 1'b0) begin
                state <= SUB4;
            end
         end
         SUB3: begin
            if(sadder_done == 1'b0) begin
            state <= SUB4;
            end
         end
         SUB4: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1) begin
                be <= sadder_out;
                //
                if(sadder_out[14] == 1'b1) begin
                temp <= 4'd0;
                end else if(sadder_out[13] == 1'b1) begin
                temp <= 4'd1;
                end else if(sadder_out[12] == 1'b1) begin
                temp <= 4'd2;
                end else if(sadder_out[11] == 1'b1) begin
                temp <= 4'd3;
                end else if(sadder_out[10] == 1'b1) begin
                temp <= 4'd4;
                end else if(sadder_out[9] == 1'b1) begin
                temp <= 4'd5;
                end else if(sadder_out[8] == 1'b1) begin
                temp <= 4'd6;
                end else if(sadder_out[7] == 1'b1) begin
                temp <= 4'd7;
                end else if(sadder_out[6] == 1'b1) begin
                temp <= 4'd8;
                end else if(sadder_out[5] == 1'b1) begin
                temp <= 4'd9;
                end else if(sadder_out[4] == 1'b1) begin
                temp <= 4'd10;
                end else if(sadder_out[3] == 1'b1) begin
                temp <= 4'd11;
                end else if(sadder_out[2] == 1'b1) begin
                temp <= 4'd12;
                end else if(sadder_out[1] == 1'b1) begin
                temp <= 4'd13;
                end else if(sadder_out[0] == 1'b1) begin
                temp <= 4'd14;
                end
                //
                sa_in <= {9'b0, aa};
                sb_in <= {9'b0, ab};
                sc_in <= 0;
                sadder_en <= 1;
                state <= SUB5;
            end
         end
         SUB5: begin
            if(sadder_done == 1'b0) begin
            state <= SUB6;
            end
         end
         SUB6: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1) begin
                if(temp == 4'd0) begin
                    res_e <= sadder_out[6:0];
                    res_m <= be[14:0];
                    state <= ALU_IDLE;
                end else begin
                    sa_in <= sadder_out;
                    sb_in <= {12'b1,~temp};
                    sc_in <= 1;
                    sadder_en <= 1;
                    state <= SUB7;
                end
            end
         end
         SUB7: begin
            if(sadder_done == 1'b0) begin
                state <= SUB8;
            end
         end
         SUB8: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1) begin
                res_e <= sadder_out[6:0];
                sa_in <= be;
                sb_in <= {12'b0,temp};
                sc_in <= 0;
                sshifter_left <= 1;
                sshifter_en <= 1;
                state <= SUB9;
            end
         end
         SUB9: begin
            if(sadder_done == 1'b0) begin
                state <= SUB10;
            end
         end
         SUB10: begin
            sadder_en <= 0;
            if(sadder_done == 1'b1) begin
                res_m <= sadder_out[14:0];
                state <= ALU_IDLE;
            end
         end
      default: begin
        state <= ALU_IDLE;
      end
   endcase
  end
end

endmodule
