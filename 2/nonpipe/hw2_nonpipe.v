module hw2_nonpipe (
    input [7:0] a, 
    input [7:0] b, 
    input [7:0] c, 
    input s, 
    output [15:0] d
);

    reg [15:0] temp;

    always @(*) begin
        if (s == 1) 
            temp = (a + b) * c;
        else
            temp = (a - b) * c;
    end

    assign d = temp;

endmodule