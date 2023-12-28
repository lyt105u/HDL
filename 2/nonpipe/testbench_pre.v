module testbench;
    reg [7 : 0] a;
    reg [7 : 0] b;
    reg [7 : 0] c;
    reg s;
    wire [15 : 0] d;

    integer i;
    reg clk = 0;
    reg [15:0] ans;

    hw2_nonpipe nonpipe (
        a,
        b,
        c,
        s,
        d
    );

    always @(a or b or c or s) begin
        if(s == 1) begin
            ans = (a + b) * c;
        end else if(s == 0) begin
            ans = (a - b) * c;
        end
    end

    initial begin
        for (i=0; i<200; i=i+1) begin
            a <= $random;
            b <= $random;
            if(i % 2 == 0) begin
                c <= 0;
            end else begin
                c <= $random;
            end
            s <= $random;

            clk = 0;
            #5
            clk = 1;
            #5

            if (ans != d) begin
                $display("a = 0x%0h,\tb = 0x%0h,\tc = 0x%0h,\ts = 0x%0h,\td = 0x%0h,\tTB_ans = 0x%0h;\tWRONG!", a, b, c, s, d, ans);
                $finish;
            end else begin
                $display("a = 0x%0h,\tb = 0x%0h,\tc = 0x%0h,\ts = 0x%0h,\td = 0x%0h,\tTB_ans = 0x%0h;\tCORRECT!", a, b, c, s, d, ans);
            end
        end
    end
endmodule
