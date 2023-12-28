module testbench;

    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] c;
    reg s;
    reg clk;
    reg reset;
    wire [15:0] d;

    integer i;
    reg [15:0] ans;

    hw2_clockgate hw2_clockgate (a, b, c, s, clk, reset, d);

    always #5 clk = ~clk;

    initial begin
        clk = 1;
        for (i=0; i<200; i=i+1) begin
            a = $random;
            b = $random;
            s = $random;
            if(i % 2 == 0) begin
                c = 0;
            end else begin
                c = $random;
            end

            if(s == 1) begin
                ans = (a + b) * c;
            end else if(s == 0) begin
                ans = (a - b) * c;
            end

            reset = 0;            

            #20 // need 2 cycles to finish the two stages of pipeline, and then we get output d
            if (ans != d) begin
                $display("a = 0x%0h,\tb = 0x%0h,\tc = 0x%0h,\ts = 0x%0h,\td = 0x%0h,\tTB_ans = 0x%0h;\tWRONG!", a, b, c, s, d, ans);
            end else begin
                $display("a = 0x%0h,\tb = 0x%0h,\tc = 0x%0h,\ts = 0x%0h,\td = 0x%0h,\tTB_ans = 0x%0h;\tCORRECT!", a, b, c, s, d, ans);
            end
            reset = 1;
            #10;
        end
        $finish;
    end
endmodule
