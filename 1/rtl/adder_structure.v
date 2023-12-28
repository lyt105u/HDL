module FA (
  sum,
  c_out,
  a,
  b,
  c_in
);
  output sum;
  output c_out;
  input a, b;
  input c_in;

  assign sum = (a ^ b) ^ c_in;
  assign c_out = (a & b) | (b & c_in) | (c_in & a);
endmodule

module adder_structure (
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
  wire [width:0] c;
  assign c[0] = ci;

  genvar i;
  generate
    for (i = 0; i < width; i = i + 1) begin : FA_loop  // block named “FA_loop”
      FA f (
        s[i],
        c[i+1],
        a[i],
        b[i],
        c[i]
      );
    end
  endgenerate
  assign co = c[width];
endmodule
