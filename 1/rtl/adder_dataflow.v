module adder_dataflow (
    s,
    co,
    a,
    b,
    ci
);
  parameter width = 32;
  output [width-1:0] s;
  output co;
  input [width-1:0] a, b;
  input ci;

  assign {co, s} = a + b + ci;
endmodule