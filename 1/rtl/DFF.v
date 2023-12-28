// module D_FF (q, d, clk);
//     output q; 
//     input d, clk; 
//     reg q;
//     always @( posedge clk)
//         q <= d;
// endmodule

module D_FF (
    input [31:0] d,
    input clk,
    output reg [31:0] q
);

always @(posedge clk) begin
    q <= d;
end

endmodule