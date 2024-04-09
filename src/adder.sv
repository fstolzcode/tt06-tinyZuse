//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2024 09:45:57 PM
// Design Name: 
// Module Name: fpu_try2
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
module alu_8bit (
    input [7:0] a,
    input [7:0] b,
    input c_in,
    output [7:0] out,
    output c_out
);
    wire [7:0] c;
    assign out[0] = a[0] ^ b[0] ^ c_in;
  assign c[0] = (a[0] & b[0]) | (a[0] & c_in) | (b[0] & c_in);
    genvar i;
    generate for(i = 1; i < 8; i = i + 1) begin
      assign out[i] = a[i] ^ b[i] ^ c[i-1];
      assign c[i] = (a[i] & b[i]) | (a[i] & c[i-1]) | (b[i] & c[i-1]);
    end
    assign c_out = c[7];
    endgenerate
endmodule

module alu_17bit (
    input [16:0] a,
    input [16:0] b,
    input c_in,
    output [16:0] out,
    output c_out
);
    wire [16:0] c;
    assign out[0] = a[0] ^ b[0] ^ c_in;
    assign c[0] = (a[0] & b[0]) | (a[0] & c_in) | (b[0] & c_in);
    genvar i;
    generate for(i = 1; i < 17; i = i + 1) begin
      assign out[i] = a[i] ^ b[i] ^ c[i-1];
      assign c[i] = (a[i] & b[i]) | (a[i] & c[i-1]) | (b[i] & c[i-1]);
    end
      assign c_out = c[16];
    endgenerate
endmodule

module shifter_17bit (
    input [16:0] in,
    input [7:0] amount,
    input left,
    output reg [16:0] out
);

 always @* begin 
    case (amount)
      5'd0: out = in;
      5'd1: out = left == 1'b1 ? {in[15:0],1'b0} : {1'b0,in[16:1]};
      5'd2: out = left == 1'b1 ? {in[14:0],2'b0} : {2'b0,in[16:2]};
      5'd3: out = left == 1'b1 ? {in[13:0],3'b0} : {3'b0,in[16:3]};
      5'd4: out = left == 1'b1 ? {in[12:0],4'b0} : {4'b0,in[16:4]};
      5'd5: out = left == 1'b1 ? {in[11:0],5'b0} : {5'b0,in[16:5]};
      5'd6: out = left == 1'b1 ? {in[10:0],6'b0} : {6'b0,in[16:6]};
      5'd7: out = left == 1'b1 ? {in[9:0],7'b0} : {7'b0,in[16:7]};
      5'd8: out = left == 1'b1 ? {in[8:0],8'b0} : {8'b0,in[16:8]};
      5'd9: out = left == 1'b1 ? {in[7:0],9'b0} : {9'b0,in[16:9]};
      5'd10: out = left == 1'b1 ? {in[6:0],10'b0} : {10'b0,in[16:10]};
      5'd11: out = left == 1'b1 ? {in[5:0],11'b0} : {11'b0,in[16:11]};
      5'd12: out = left == 1'b1 ? {in[4:0],12'b0} : {12'b0,in[16:12]};
      5'd13: out = left == 1'b1 ? {in[3:0],13'b0} : {13'b0,in[16:13]};
      5'd14: out = left == 1'b1 ? {in[2:0],14'b0} : {14'b0,in[16:14]};
      5'd15: out = left == 1'b1 ? {in[1],15'b0} : {15'b0,in[16:15]};
      5'd16: out = left == 1'b1 ? {in[0],16'b0} : {16'b0,in[15]};
    default: out = 0;
    endcase
end
endmodule

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
ADD5 = 4'd6, ADD6=4'd7, SUB0=4'd8, SUB1 = 4'd9, SUB2=4'd10, SUB3=4'd11;

reg   [SIZE-1:0]          state        ;// Seq part of the FSM

reg [16:0] alu_a;
reg [16:0] alu_b;
reg alu_cin;
wire [16:0] alu_out;
wire alu_cout;
alu_17bit alu(
    .a(alu_a),
    .b(alu_b),
    .c_in(alu_cin),
    .out(alu_out),
    .c_out(alu_cout)
);


reg [16:0] alu8_a;
reg [16:0] alu8_b;
reg alu8_cin;
wire [16:0] alu8_out;
wire alu8_cout;
alu_8bit alu8(
    .a(alu8_a),
    .b(alu8_b),
    .c_in(alu8_cin),
    .out(alu8_out),
    .c_out(alu8_cout)
);

reg [16:0] shifter_in;
reg [7:0] shifter_amount;
reg shifter_left;
wire [16:0] shifter_out;
shifter_17bit shifter(
    .in(shifter_in),
    .amount(shifter_amount),
    .left(shifter_left),
    .out(shifter_out)
);

reg[7:0] aa;
reg[7:0] ab;

reg[16:0] ba;
reg[16:0] bb;

reg operation;

always @ (posedge clk)
begin : OUTPUT_LOGIC
  if(reset == 1'b1) begin
    state <= ALU_IDLE;
  end else begin
      case(state)
      ALU_IDLE: begin
          idle <= 1;
          if(add == 1'b1) begin
            operation <= 0;
            state <= ADD0;
          end else if (sub == 1'b1) begin
            state <= ADD0;
            operation <= 1;
          end
      end
      ADD0: begin
          idle <= 0;
          alu8_a <= { reg1_e[6] , reg1_e};
          alu8_b <= { ~reg2_e[6] , ~reg2_e};
          alu8_cin <= 1;
          state <= ADD1;
          end
      ADD1: begin
         if(alu8_out[7] == 1'b0) begin
                 $display("POSITIVE");
                // POSITIVE
                ab <= 0;
                aa <= reg1_e;
                
                ba <= {2'b0,reg1_m};
                shifter_in <= {2'b0,reg2_m};
                shifter_amount <= alu8_out[7:0];
                shifter_left <= 0;
                state <= ADD2;
            end else begin
            $display("NEGATIVE");
                // NEGATIVE
                aa <= 0;
                ab <= reg2_e;
                
                ba <= {2'b0,reg2_m};
                alu8_a <= ~alu8_out;
                alu8_b <= 1;
                alu8_cin <= 0;
                state <= ADD5;
            end
      end
      ADD2: begin
        alu_a <= ba;
        alu_b <= (operation == 1'b1) ? ~shifter_out : shifter_out;
        alu_cin <= operation;
        state <= (operation == 1'b1) ? SUB0 : ADD3;
      end
      ADD3: begin
        alu8_a <= aa;
        alu8_b <= ab;
        if( (alu_out[16] | alu_out [15]) == 1'b1) begin
            $display("BE>2");
            res_m <= alu_out[15:1];
            alu8_cin <= 1;
        end else begin
            $display("BE<2");
            res_m <= alu_out[14:0];
            alu8_cin <= 0;
        end
        state <= ADD4;
      end
      ADD4: begin
        res_e <= alu8_out[6:0];
        state <= ALU_IDLE;
      end
      ADD5: begin
         shifter_in <= {2'b0,reg1_m};
         shifter_amount <= alu8_out[7:0];
         shifter_left <= 0;
         state <= ADD2;
      end
      SUB0: begin
        if(alu_out[16] == 1'b1) begin
             $display("SUB NEGATIVE");
            alu_a <= ~alu_out;
            alu_b <= 1;
            alu_cin <= 0;
            state <= SUB1;
        end else begin
         $display("SUB POSITIVE");
            alu_a <= alu_out;
            alu_b <= 0;
            alu_cin <= 0;
            state <= SUB1;
        end
      end
      SUB1: begin
         alu8_a <= { aa[6] , aa};
         alu8_b <= { ab[6] , ab};
         alu8_cin <= 0;
         state <= SUB2;
      end
      SUB2: begin
        alu8_a <= alu8_out;
        alu8_cin <= 1;
        shifter_in <= alu_out;
        shifter_left <= 1;
        if(alu_out[14] == 1'b1) begin
               alu8_b <= ~8'd0;
               shifter_amount <= 5'd0;
        end else if(alu_out[13] == 1'b1) begin
                alu8_b <= ~8'd1;
                shifter_amount <= 5'd1;
                end else if(alu_out[12] == 1'b1) begin
                alu8_b <= ~8'd2;
                shifter_amount <= 5'd2;
                end else if(alu_out[11] == 1'b1) begin
                alu8_b <= ~8'd3;
                shifter_amount <= 5'd3;
                end else if(alu_out[10] == 1'b1) begin
                alu8_b <= ~8'd4;
                shifter_amount <= 5'd4;
                end else if(alu_out[9] == 1'b1) begin
                alu8_b <= ~8'd5;
                shifter_amount <= 5'd5;
                end else if(alu_out[8] == 1'b1) begin
                alu8_b <= ~8'd6;
                shifter_amount <= 5'd6;
                end else if(alu_out[7] == 1'b1) begin
                alu8_b <= ~8'd7;
                shifter_amount <= 5'd7;
                end else if(alu_out[6] == 1'b1) begin
                alu8_b <= ~8'd8;
                shifter_amount <= 5'd8;
                end else if(alu_out[5] == 1'b1) begin
                alu8_b <= ~8'd9;
                shifter_amount <= 5'd9;
                end else if(alu_out[4] == 1'b1) begin
                alu8_b <= ~8'd10;
                shifter_amount <= 5'd10;
                end else if(alu_out[3] == 1'b1) begin
                alu8_b <= ~8'd11;
                shifter_amount <= 5'd11;
                end else if(alu_out[2] == 1'b1) begin
                alu8_b <= ~8'd12;
                shifter_amount <= 5'd12;
                end else if(alu_out[1] == 1'b1) begin
                alu8_b <= ~8'd13;
                shifter_amount <= 5'd13;
                end else if(alu_out[0] == 1'b1) begin
                alu8_b <= ~8'd14;
                shifter_amount <= 5'd14;
                end
                state <= SUB3;
      end
      SUB3: begin
        res_e <= alu8_out;
        res_m <= shifter_out[14:0];
        state <= ALU_IDLE;
      end
      default: begin
        state <= ALU_IDLE;
      end
   endcase
  end
end
endmodule