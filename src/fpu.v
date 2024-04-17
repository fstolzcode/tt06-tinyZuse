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
    output of,
    output uf
);
    wire [7:0] c;
    assign out[0] = a[0] ^ b[0] ^ c_in;
  assign c[0] = (a[0] & b[0]) | (a[0] & c_in) | (b[0] & c_in);
    genvar i;
    generate for(i = 1; i < 8; i = i + 1) begin
      assign out[i] = a[i] ^ b[i] ^ c[i-1];
      assign c[i] = (a[i] & b[i]) | (a[i] & c[i-1]) | (b[i] & c[i-1]);
    end
    //assign u = c[5];
    assign of = ((out[7] == 1'b0) && (c[5] == 1'b1)) ? 1 : 0;
    assign uf = ((out[7] == 1'b1 && c[5] == 1'b0)) ? 1 : 0;
    endgenerate
endmodule

module alu_18bit (
    input [17:0] a,
    input [17:0] b,
    input c_in,
    output [17:0] out
);
    wire [17:0] c;
    assign out[0] = a[0] ^ b[0] ^ c_in;
    assign c[0] = (a[0] & b[0]) | (a[0] & c_in) | (b[0] & c_in);
    genvar i;
    generate for(i = 1; i < 18; i = i + 1) begin
      assign out[i] = a[i] ^ b[i] ^ c[i-1];
      assign c[i] = (a[i] & b[i]) | (a[i] & c[i-1]) | (b[i] & c[i-1]);
    end
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
      8'd0: out = in;
      8'd1: out = left == 1'b1 ? {in[15:0],1'b0} : {1'b0,in[16:1]};
      8'd2: out = left == 1'b1 ? {in[14:0],2'b0} : {2'b0,in[16:2]};
      8'd3: out = left == 1'b1 ? {in[13:0],3'b0} : {3'b0,in[16:3]};
      8'd4: out = left == 1'b1 ? {in[12:0],4'b0} : {4'b0,in[16:4]};
      8'd5: out = left == 1'b1 ? {in[11:0],5'b0} : {5'b0,in[16:5]};
      8'd6: out = left == 1'b1 ? {in[10:0],6'b0} : {6'b0,in[16:6]};
      8'd7: out = left == 1'b1 ? {in[9:0],7'b0} : {7'b0,in[16:7]};
      8'd8: out = left == 1'b1 ? {in[8:0],8'b0} : {8'b0,in[16:8]};
      8'd9: out = left == 1'b1 ? {in[7:0],9'b0} : {9'b0,in[16:9]};
      8'd10: out = left == 1'b1 ? {in[6:0],10'b0} : {10'b0,in[16:10]};
      8'd11: out = left == 1'b1 ? {in[5:0],11'b0} : {11'b0,in[16:11]};
      8'd12: out = left == 1'b1 ? {in[4:0],12'b0} : {12'b0,in[16:12]};
      8'd13: out = left == 1'b1 ? {in[3:0],13'b0} : {13'b0,in[16:13]};
      8'd14: out = left == 1'b1 ? {in[2:0],14'b0} : {14'b0,in[16:14]};
      8'd15: out = left == 1'b1 ? {in[1:0],15'b0} : {15'b0,in[16:15]};
      8'd16: out = left == 1'b1 ? {in[0],16'b0} : {16'b0,in[16]};
    default: out = 0;
    endcase
end
endmodule

module inf_checker (
    input [6:0] e1,
    input [6:0] e2,
    input [6:0] e3,
    output inf
);
    assign inf = ((e1 == 7'b0111111) || (e2 == 7'b0111111) || (e3 == 7'b0111111)) ? 1 : 0;
endmodule 

module zero_checker (
    input [6:0] e1,
    input [6:0] e2,
    output zero
);
    assign zero = ((e1 == 7'b1000000) || (e2 == 7'b1000000)) ? 1 : 0;
endmodule 

module fpu(
    input wire clk,
    input wire reset,
    input wire add,
    input wire sub,
    input wire mul,
    input wire div,
    input wire sqrt,
    input wire reg1_s,
    input [6:0] reg1_e,
    input [14:0] reg1_m,
    input wire reg2_s,
    input [6:0] reg2_e,
    input [14:0] reg2_m,
    output reg res_s,
    output reg [6:0] res_e,
    output reg [14:0] res_m,
    output reg zero_flag,
    output reg overflow_flag,
    output reg underflow_flag,
    output reg idle
    );

localparam SIZE = 5           ;
localparam ALU_IDLE  = 5'd0,
ADD0 = 5'd1,ADD1 = 5'd2,ADD2 = 5'd3,ADD3 = 5'd4,ADD4 = 5'd5,
ADD5 = 5'd6, SUB0=5'd7, SUB1 = 5'd8, SUB2=5'd9, SUB3=5'd10, 
ZEROCHECK = 5'd11, INFCHECK = 5'd12,
MUL0 = 5'd13, MUL1 = 5'd14, MUL2 = 5'd15, MUL3 = 5'd16,
DIV0 = 5'd17, DIV1 = 5'd18, DIV2 = 5'd19, DIV3 = 5'd20,
SQRT0 = 5'd21, SQRT1 = 5'd22, SQRT2 = 5'd23;

reg   [SIZE-1:0]          state        ;// Seq part of the FSM

reg [17:0] alu_a;
reg [17:0] alu_b;
reg alu_cin;
wire [17:0] alu_out;
alu_18bit alu(
    .a(alu_a),
    .b(alu_b),
    .c_in(alu_cin),
    .out(alu_out)
);


reg [7:0] alu8_a;
reg [7:0] alu8_b;
reg alu8_cin;
wire [7:0] alu8_out;
//wire alu8_u;
wire alu8_of;
wire alu8_uf;
alu_8bit alu8(
    .a(alu8_a),
    .b(alu8_b),
    .c_in(alu8_cin),
    .out(alu8_out),
    .of(alu8_of),
    .uf(alu8_uf)
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

reg[17:0] ba;

reg operation;
reg bs;

reg flag62;

wire inf_check;
inf_checker inf_inst(
    .e1(reg1_e),
    .e2(reg2_e),
    .e3(alu8_out[6:0]),
    .inf(inf_check)
);

wire zero_check;
zero_checker zero_inst(
    .e1(reg1_e),
    .e2(reg2_e),
    .zero(zero_check)
);
reg inf;

always @ (posedge clk)
begin : OUTPUT_LOGIC
  if(reset == 1'b1) begin
    aa <= 0;
    ab <= 0;
    ba <= 0;
    operation <= 0;
    bs <= 0;
    shifter_in <= 0;
    shifter_amount <= 0;
    shifter_left <= 0;
    alu8_a <= 0;
    alu8_b <= 0;
    alu8_cin <= 0;
    flag62 <= 0;
    alu_a <= 0;
    alu_b <= 0;
    alu_cin <= 0;
    res_s <= 0;
    res_e <= 0;
    res_m <= 0;
    zero_flag <= 0;
    overflow_flag <= 0;
    underflow_flag <= 0;
    inf <= 0;
    state <= ALU_IDLE;
  end else begin
      case(state)
      ALU_IDLE: begin
          idle <= 1;
          inf <= 0;
          flag62 <= 0;
          if (mul == 1'b1 || div == 1'b1) begin
            if(reg1_s != reg2_s) begin
                res_s <= 0;
            end else begin
                res_s <= 1;
            end
          end
          if(add == 1'b1) begin
            bs <= reg2_s;
            operation <= (reg1_s == reg2_s) ? 0 : 1;
            state <= ADD0;
          end else if (sub == 1'b1) begin
            bs <= ~reg2_s;
            operation <= (reg1_s == reg2_s) ? 1 : 0;
            state <= ADD0;
          end else if (mul == 1'b1) begin
            state <= MUL0;
          end else if (div == 1'b1) begin
            state <= DIV0;
          end else if (sqrt == 1'b1) begin
            state <= SQRT0;
          end 
      end
      ADD0: begin
          inf <= inf | inf_check;
          zero_flag <= 0;
          overflow_flag <= 0;
          underflow_flag <= 0;
          idle <= 0;
          alu8_a <= { 1'b0 , reg1_e};
          alu8_b <= { 1'b0 , ~reg2_e};
          alu8_cin <= 1;
          state <= ADD1;
          end
      ADD1: begin
         overflow_flag <= overflow_flag | alu8_of;
         underflow_flag <= underflow_flag | alu8_uf;
         inf <= inf | inf_check;
         if(alu8_out[6] == 1'b0) begin
                $display("POSITIVE");
                // POSITIVE
                ab <= 0;
                aa <= { 1'b0,reg1_e};
                flag62 <= (reg1_e == 7'b0111110 ) ? 1 : 0;
                
                res_s <= reg1_s;
                
                ba <= {3'b0,reg1_m};
                shifter_in <= {2'b0,reg2_m};
                shifter_amount <= {1'b0,alu8_out[6:0]};
                shifter_left <= 0;
                state <= ADD2;
            end else begin
            $display("NEGATIVE");
                // NEGATIVE
                aa <= 0;
                ab <= { 1'b0,reg2_e};
                flag62 <= (reg2_e == 7'b0111110 ) ? 1 : 0;
                
                res_s <= bs;
                
                ba <= {3'b0,reg2_m};
                alu8_a <= ~alu8_out;
                alu8_b <= 1;
                alu8_cin <= 0;
                state <= ADD5;
            end
      end
      ADD2: begin
        alu_a <= ba;
        alu_b <= (operation == 1'b1) ? {~shifter_out[16],~shifter_out} : {shifter_out[16],shifter_out};
        alu_cin <= operation;
        state <= (operation == 1'b1) ? SUB0 : ADD3;
      end
      ADD3: begin
        alu8_a <= aa;
        alu8_b <= ab;
        if (alu_out[17] == 1'b1) begin
            $display("B NEGATIVE SIGN");
            res_s <= ~res_s;
        end 
        if( (alu_out [15]) == 1'b1) begin
            $display("BE>2");
            res_m <= alu_out[15:1];
            alu8_cin <= 1;
        end else begin
            $display("BE<2");
            res_m <= alu_out[14:0];
            alu8_cin <= 0;
            flag62 <= 0;
        end
        state <= ADD4;
      end
      ADD4: begin
        overflow_flag <= overflow_flag | alu8_of | (alu8_out[7] & flag62);
        underflow_flag <= underflow_flag | alu8_uf;
        inf <= inf | inf_check;
        res_e <= alu8_out[6:0];
        state <= ZEROCHECK;
      end
      ADD5: begin
         shifter_in <= {2'b0,reg1_m};
         shifter_amount <= {1'b0,alu8_out[6:0]};
         shifter_left <= 0;
         state <= ADD2;
      end
      SUB0: begin
        if(alu_out[16] == 1'b1) begin
            res_s <= ~res_s;
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
         alu8_a <= aa;
         alu8_b <= ab;
         alu8_cin <= 0;
         state <= SUB2;
      end
      SUB2: begin
        inf <= inf | inf_check;
        alu8_a <= {1'b0,alu8_out[6:0]};
        alu8_cin <= 1;
        shifter_in <= alu_out[16:0];
        shifter_left <= 1;
        if(alu_out[14] == 1'b1) begin
               alu8_b <= {1'b0,~7'd0};
               shifter_amount <= 8'd0;
        end else if(alu_out[13] == 1'b1) begin
                alu8_b <= {1'b0,~7'd1};
                shifter_amount <= 8'd1;
                end else if(alu_out[12] == 1'b1) begin
                alu8_b <= {1'b0,~7'd2};
                shifter_amount <= 8'd2;
                end else if(alu_out[11] == 1'b1) begin
                alu8_b <= {1'b0,~7'd3};
                shifter_amount <= 8'd3;
                end else if(alu_out[10] == 1'b1) begin
                alu8_b <= {1'b0,~7'd4};
                shifter_amount <= 8'd4;
                end else if(alu_out[9] == 1'b1) begin
                alu8_b <= {1'b0,~7'd5};
                shifter_amount <= 8'd5;
                end else if(alu_out[8] == 1'b1) begin
                alu8_b <= {1'b0,~7'd6};
                shifter_amount <= 8'd6;
                end else if(alu_out[7] == 1'b1) begin
                alu8_b <= {1'b0,~7'd7};
                shifter_amount <= 8'd7;
                end else if(alu_out[6] == 1'b1) begin
                alu8_b <= {1'b0,~7'd8};
                shifter_amount <= 8'd8;
                end else if(alu_out[5] == 1'b1) begin
                alu8_b <= {1'b0,~7'd9};
                shifter_amount <= 8'd9;
                end else if(alu_out[4] == 1'b1) begin
                alu8_b <= {1'b0,~7'd10};
                shifter_amount <= 8'd10;
                end else if(alu_out[3] == 1'b1) begin
                alu8_b <= {1'b0,~7'd11};
                shifter_amount <= 8'd11;
                end else if(alu_out[2] == 1'b1) begin
                alu8_b <= {1'b0,~7'd12};
                shifter_amount <= 8'd12;
                end else if(alu_out[1] == 1'b1) begin
                alu8_b <= {1'b0,~7'd13};
                shifter_amount <= 8'd13;
                end else if(alu_out[0] == 1'b1) begin
                alu8_b <= {1'b0,~7'd14};
                shifter_amount <= 8'd14;
                end
                state <= SUB3;
      end
      SUB3: begin
        overflow_flag <= overflow_flag | alu8_of;
        underflow_flag <= underflow_flag | alu8_uf;
        inf <= inf | inf_check;
        res_e <= alu8_out[6:0];
        res_m <= shifter_out[14:0];
        state <= ZEROCHECK;
      end
      ZEROCHECK: begin
        if( |res_m != 1'b1 || zero_flag == 1'b1) begin
            zero_flag <= 1;
            res_e <= 7'b1000000;
            res_m <= 15'b100000000000000;
        end
        state <= INFCHECK;
      end
      INFCHECK: begin
        if( inf == 1'b1) begin
            res_e <= 7'b0111111;
            res_m <= 15'b100000000000000;
        end
        state <= ALU_IDLE;
      end
      MUL0: begin
        idle <= 0;
        alu8_a <= 0;
        alu8_b <= 0;
        alu8_cin <= 0;
        alu_a <= 0;
        alu_b <= 0;
        alu_cin <= 0;
        inf <= inf | inf_check;
        zero_flag <= zero_check;
        overflow_flag <= 0;
        underflow_flag <= 0;
        state <= MUL1;
      end
      MUL1: begin
        if(alu8_out[3:0] == 4'd14) begin
            state <= MUL2;
        end else begin
            state <= MUL1;
        end
        alu_a <= {2'b0,alu_out[16:1]};
        alu_b <= reg1_m[alu8_out[3:0]] == 1'b1 ? {3'b0, reg2_m} : 18'b0;
        alu_cin <= 0;
        alu8_a <= alu8_out;
        alu8_b <= 1;
      end
      MUL2: begin
        if(alu_out[15] == 1'b1) begin
            res_m <= alu_out[15:1];
            alu8_cin <= 1;
        end else begin
            res_m <= alu_out[14:0];
            alu8_cin <= 0;
        end
        alu8_a <= {1'b0,reg1_e};
        alu8_b <= {1'b0,reg2_e};
        state <= MUL3;
      end
      MUL3: begin
        overflow_flag <= overflow_flag | alu8_of;
        underflow_flag <= underflow_flag | alu8_uf;
        inf <= inf | inf_check;
        res_e <= alu8_out[6:0];
        state <= ZEROCHECK;
      end
      DIV0: begin
        inf <= inf | zero_check;
        zero_flag <= inf_check;
        idle <= 0;
        alu8_a <= 8'd14;
        alu8_b <= 0;
        alu8_cin <= 0;
        ba <= {3'b00, reg1_m};
        alu_a <= {3'b000, reg1_m};
        alu_b <= {3'b111, ~reg2_m};
        alu_cin <= 1;
        overflow_flag <= 0;
        underflow_flag <= 0;
        state <= DIV1;
      end
      DIV1: begin
        if(alu8_out[3:0] == 4'd0) begin
            alu8_a <= {1'b0,reg1_e};
            alu8_b <= {1'b1,~reg2_e};
            alu8_cin <= 1;
            state <= DIV2;
        end else begin
            alu8_a <= alu8_out;
            alu8_b <= 8'b11111110;
            alu8_cin <= 1;
            state <= DIV1;
        end
         alu_a <=  (alu_out[17] == 1'b0) ? {alu_out[16:0],1'b0} : {ba[16:0],1'b0};
         ba <= (alu_out[17] == 1'b0) ? {alu_out[16:0],1'b0} : {ba[16:0],1'b0};
         res_m[alu8_out[3:0]] <= (alu_out[17] == 1'b0) ? 1 : 0;
         
      end
      DIV2: begin
        inf <= inf | inf_check;
        if(res_m[14] != 1'b1) begin
            res_m <= {res_m[13:0], 1'b0};
            alu8_a <= alu8_out;
            alu8_b <= ~8'b1;
            alu8_cin <= 1;
        end
        state <= DIV3;
      end
      DIV3: begin
         inf <= inf | inf_check;
         res_e <= alu8_out[6:0];
         state <= ZEROCHECK;
      end
      SQRT0: begin
        idle <= 0;
        inf <= inf | inf_check;
        zero_flag <= zero_check;
        overflow_flag <= 0;
        underflow_flag <= 0;
        
        alu8_a <= 8'd14;
        alu8_b <= 0;
        alu8_cin <= 0;
        alu_a <= (reg1_e[0] == 1'b1) ? {2'b0,reg1_m,1'b0} : {3'b0,reg1_m};
        ba <= (reg1_e[0] == 1'b1) ? {2'b0,reg1_m,1'b0} : {3'b0,reg1_m};
        alu_b <= ~18'b000100000000000000;
        alu_cin <= 1;
        res_m <= 0;
        shifter_in <= 17'b00100000000000000;
        shifter_left <= 0;
        shifter_amount <= 8'd1;
        state <= SQRT1;
      end
      SQRT1: begin
         if(alu8_out[3:0] == 4'd0) begin
            state <= SQRT2;
        end else begin
            alu8_a <= alu8_out;
            alu8_b <= 8'b11111110;
            alu8_cin <= 1;
            state <= SQRT1;
        end
        alu_a <= (alu_out[17] == 1'b0) ? {alu_out[16:0],1'b0} : {ba[16:0],1'b0};
        ba <= (alu_out[17] == 1'b0) ? {alu_out[16:0],1'b0} : {ba[16:0],1'b0};
        res_m[alu8_out[3:0]] <= (alu_out[17] == 1'b0) ? 1 : 0;
        alu_b <= ~( {2'b0, {(alu_out[17] == 1'b0) ? (res_m |  {shifter_out[13:0],1'b0} ) : res_m} ,1'b0} | {1'b0,shifter_out});
        shifter_in <= shifter_out;
      end
      SQRT2: begin
        res_s <= 1;
        res_e <= {1'b0,reg1_e[6:1]};
        state <= ZEROCHECK;
      end
      default: begin
        state <= ALU_IDLE;
      end
   endcase
  end
end
endmodule