module stage1 (
    input [7:0] a,
    input [7:0] b,
    input s,
    input clk,
    input reset,
    output [15:0] output1
);
    reg [15:0] reg_sum;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            reg_sum <= 8'b0;
        else if (s)
            reg_sum <= a + b;
        else
            reg_sum <= a - b;
    end

    assign output1 = reg_sum;
endmodule

module stage2 (
    input [7:0] c,
    input clk,
    input reset,
    input [15:0] output1,
    output [15:0] result
);
    reg [15:0] reg_result;
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            reg_result <= 16'b0;
        end
        else begin
            reg_result <= output1 * c;
        end
    end

    assign result = reg_result;
endmodule

module hw2_pipe (
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    input s,
    input clk,
    input reset,
    output [15:0] d
);
    wire [15:0] output1;
    stage1 stage1_inst (a, b, s, clk, reset, output1);
    stage2 stage2_inst (c, clk, reset, output1, d);
endmodule
