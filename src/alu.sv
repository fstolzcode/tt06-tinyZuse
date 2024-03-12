`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2024 05:11:17 PM
// Design Name: 
// Module Name: alu
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


// Code your design here
module alu_a (
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

module ba_shifter (
    input [14:0] in,
    input [1:0] amount,
    input left,
    output [16:0] out
);

reg [14:0] out_reg;
always_comb begin 
    case (amount)
      2'd1: out_reg = left == 1'b1 ? {1'b0, in[13:0], 1'b0} : {3'b0,in[14:1]};
      2'd2: out_reg = left == 1'b1 ? {2'b0,in[12:0], 1'b0} : {4'b0,in[14:2]};
    default: out_reg = in;
    endcase
end
assign out = out_reg;
endmodule

module bb_shifter (
    input [15:0] in,
    input [4:0] amount,
    input left,
    output [15:0] out
);

reg [15:0] out_reg;
always_comb begin 
    case (amount)
      5'd1: out_reg = left == 1'b1 ? {in[14:0],1'b0} : {1'b0,in[15:1]};
      5'd2: out_reg = left == 1'b1 ? {in[13:0],2'b0} : {2'b0,in[15:2]};
      5'd3: out_reg = left == 1'b1 ? {in[12:0],3'b0} : {3'b0,in[15:3]};
      5'd4: out_reg = left == 1'b1 ? {in[11:0],4'b0} : {4'b0,in[15:4]};
      5'd5: out_reg = left == 1'b1 ? {in[10:0],5'b0} : {5'b0,in[15:5]};
      5'd6: out_reg = left == 1'b1 ? {in[9:0],6'b0} : {6'b0,in[15:6]};
      5'd7: out_reg = left == 1'b1 ? {in[8:0],7'b0} : {7'b0,in[15:7]};
      5'd8: out_reg = left == 1'b1 ? {in[7:0],8'b0} : {8'b0,in[15:8]};
      5'd9: out_reg = left == 1'b1 ? {in[6:0],9'b0} : {9'b0,in[15:9]};
      5'd10: out_reg = left == 1'b1 ? {in[5:0],10'b0} : {10'b0,in[15:10]};
      5'd11: out_reg = left == 1'b1 ? {in[4:0],11'b0} : {11'b0,in[15:11]};
      5'd12: out_reg = left == 1'b1 ? {in[3:0],12'b0} : {12'b0,in[15:12]};
      5'd13: out_reg = left == 1'b1 ? {in[2:0],13'b0} : {13'b0,in[15:13]};
      5'd14: out_reg = left == 1'b1 ? {in[1:0],14'b0} : {14'b0,in[15:14]};
      5'd15: out_reg = left == 1'b1 ? {in[0],15'b0} : {15'b0,in[15]};
      5'd16: out_reg = left == 1'b1 ? {16'b0} : {16'b0};
    default: out_reg = in;
    endcase
end
assign out = out_reg;
endmodule

module alu_b (
    input [16:0] a,
    input [15:0] b,
    input c_in,
    output [15:0] out,
    output c_out
);
    wire [16:0] b_ex = {1'b0,b[15:0]};
    wire [16:0] c;
    assign out[0] = a[0] ^ b_ex[0] ^ c_in;
    assign c[0] = (a[0] & b_ex[0]) | (a[0] & c_in) | (b_ex[0] & c_in);
    genvar i;
    generate for(i = 1; i < 16; i = i + 1) begin
      assign out[i] = a[i] ^ b_ex[i] ^ c[i-1];
      assign c[i] = (a[i] & b_ex[i]) | (a[i] & c[i-1]) | (b_ex[i] & c[i-1]);
    end
      assign c_out = (a[16] & b_ex[16]) | (a[16] & c[15]) | (b_ex[16] & c[15]);
    endgenerate
endmodule
