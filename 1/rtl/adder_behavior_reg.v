module adder_behavior_reg (
  s,
  co,
  a,
  b,
  ci,
  clk
);
  parameter width = 32;
  output [width-1:0] s;
  output reg co;
  input [width-1:0] a, b;
  input ci, clk;
  reg [width-1:0] sum;

  always @(a, b, ci) begin
    {co, sum} = a + b + ci;
  end

  D_FF ff (
    sum,
    clk,
    s
  );
endmodule