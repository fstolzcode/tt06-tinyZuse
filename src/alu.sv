module full_adder(
  input wire a,
  input wire b,
  input wire c_in,
  output wire out,
  output wire c_out
);
  assign out = a ^ b ^ c_in;
  assign c_out =  (a & b) | (a & c_in) | (b & c_in);
endmodule

module shift_register(
  input wire clk,
  input wire reset,
  input wire en,
  input wire latch,
  input wire left,
  input wire shift_in,
  input wire [16:0] a,
  output wire [16:0] out
);
  reg [16:0] shift_reg;
  assign out = shift_reg;
  always @(posedge clk) begin
    if(reset == 1'b1) begin
      shift_reg <= 0;
    end else if(latch == 1'b1) begin
      shift_reg <= a;
    end else if(en == 1'b1) begin
      if(left == 1'b1) begin
        shift_reg <= {shift_reg[15:0],shift_in};
      end else begin
        shift_reg <= {shift_in,shift_reg[16:1]};
      end
    end
  end
endmodule

module serial_shifter(
    input wire clk,
    input wire reset,
    input wire en,
    input wire left,
    input wire [16:0] a,
    input wire [4:0] amount,
    output reg done,
    output reg [16:0] out
    
);
   reg shift_en;
   reg shift_latch;
   wire [16:0] shift_out;
   shift_register internal_shift(
    .clk(clk),
    .reset(reset),
    .en(shift_en),
    .latch(shift_latch),
    .left(left),
    .shift_in(1'b0),
    .a(a),
    .out(shift_out)
  );
  
  parameter FSMS_SIZE = 3;
  parameter FSMS_IDLE = 3'd0, FSMS_LATCH = 3'd1, FSMS_LATCH_SETTLE = 3'd2, FSMS_SHIFT = 3'd3, FSMS_RESULT = 3'd4;
  reg [FSMS_SIZE-1:0] state;
  reg [4:0] cnt;
  always @(posedge clk) begin
    if(reset == 1'b1) begin
        out <= 0;
        done <= 0;
        shift_en <= 0;
        shift_latch <= 0;
        cnt <= 0;
        state <= FSMS_IDLE;
    end else begin
        case(state)
            FSMS_IDLE: begin
                done <= 1;
                shift_en <= 0;
                shift_latch <= 0;
                cnt <= 0;
                if(en == 1'b1) begin
                    state <= FSMS_LATCH;
                end
            end
            FSMS_LATCH: begin
                done <= 0;
                shift_latch <= 1;
                state <= FSMS_LATCH_SETTLE;
            end
            FSMS_LATCH_SETTLE: begin
                shift_latch <= 0;
                state <= FSMS_SHIFT;
            end
            FSMS_SHIFT: begin
                if(cnt == amount) begin
                    shift_en <= 0;
                    state <= FSMS_RESULT;
                end else begin
                     shift_en <= 1;
                     cnt <= cnt + 1'b1;
                end
            end
            FSMS_RESULT: begin
                out <= shift_out;
                state <= FSMS_IDLE;
            end
        endcase
    end
  end
endmodule

module serial_adder(
  input wire clk,
  input wire reset,
  input wire en,
  input wire [16:0] a,
  input wire [16:0] b,
  input c_in,
  output reg done,
  output reg [16:0] out,
  output reg c_out
);
  
  reg shift_en;
  reg shift_latch;
  wire [16:0] shift_out_a;
  shift_register a_shift(
    .clk(clk),
    .reset(reset),
    .en(shift_en),
    .latch(shift_latch),
    .left(1'b0),
    .shift_in(1'b0),
    .a(a),
    .out(shift_out_a)
  );
  
  wire [16:0] shift_out_b;
  shift_register b_shift(
    .clk(clk),
    .reset(reset),
    .en(shift_en),
    .latch(shift_latch),
    .left(1'b0),
    .shift_in(1'b0),
    .a(b),
    .out(shift_out_b)
  );
  
  wire [16:0] shift_out_result;
  wire fa_out;
  shift_register result_shift(
    .clk(clk),
    .reset(reset),
    .en(shift_en),
    .latch(shift_latch),
    .left(1'b0),
    .shift_in(fa_out),
    .a(17'b0),
    .out(shift_out_result)
  );
  
  wire fa_c_out;
  reg fa_c_in;
  full_adder full_adder_ins(
    .a(shift_out_a[0]),
    .b(shift_out_b[0]),
    .c_in(fa_c_in),
    .out(fa_out),
    .c_out(fa_c_out)
  );
  
  parameter FSMA_SIZE = 3;
  parameter FSMA_IDLE = 3'd0, FSMA_LATCH = 3'd1, FSMA_LATCH_SETTLE = 3'd2, FSMA_ADD = 3'd3, FSMA_RESULT = 3'd4;
  reg [FSMA_SIZE-1:0] state;
  reg [4:0] cnt;
  always @(posedge clk) begin
    if (reset == 1'b1) begin
        state <= FSMA_IDLE;
      	cnt <= 0;
      	done <= 0;
     	shift_en <= 0;
      	shift_latch <= 0;
      	fa_c_in <= 0;
      	c_out <= 0;
      	out <= 0;
    end else begin
      case(state)
        FSMA_IDLE: begin
          cnt <= 0;
      	  done <= 1;
     	  shift_en <= 0;
      	  shift_latch <= 0;
      	  fa_c_in <= 0;
          if(en == 1'b1) begin
            state <= FSMA_LATCH;
          end
        end
        FSMA_LATCH: begin
          done <= 0;
          shift_latch <= 1;
          state <= FSMA_LATCH_SETTLE;
        end
        FSMA_LATCH_SETTLE: begin
          shift_latch <= 0;
          state <= FSMA_ADD;
        end
        FSMA_ADD: begin
          shift_en <= 1;
		  fa_c_in <= (cnt == 5'd0) ? c_in : fa_c_out;
          cnt <= cnt + 5'd1;
          if(cnt == 5'd17) begin
            c_out <= fa_c_out;
            state <= FSMA_RESULT;
          end
        end
        FSMA_RESULT: begin
            out <= shift_out_result;
            state <= FSMA_IDLE;
        end
      endcase
    end
  end
endmodule