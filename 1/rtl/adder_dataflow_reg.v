module adder_dataflow_reg (
    s,
    co,
    a,
    b,
    ci,
    clk
);
  parameter width = 32;
  output [width-1:0] s;
  output co;
  input [width-1:0] a, b;
  input ci, clk;
  wire [width-1:0] sum;

  assign {co, sum} = a + b + ci;

  D_FF ff (
    sum,
    clk,
    s
  );
endmodule