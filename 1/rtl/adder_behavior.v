module adder_behavior (
  s,
  co,
  a,
  b,
  ci
);
  parameter width = 32;
  input [width-1:0] a, b;
  input ci;
  output reg [width-1:0] s;
  output reg co;

  always @(a, b, ci) begin
    {co, s} = a + b + ci;
  end
endmodule