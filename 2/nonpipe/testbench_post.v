`define SDFFILE1 "./dc_out_file/hw2_nonpipe_syn.sdf"
`timescale 1ns/1ns
module testbench;
    parameter width = 8;
    reg [width-1 : 0] a;
    reg [width-1 : 0] b;
    reg [width-1 : 0] c;
    reg s;
    wire [width-1 : 0] d;
    integer i;
    reg clk = 0;
    reg [width-1:0] ans;

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
        $sdf_annotate(`SDFFILE1, nonpipe);

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
            #20
            clk = 1;
            #20

            if (ans != d) begin
                $display("a = 0x%0h,\tb = 0x%0h,\tc = 0x%0h,\ts = 0x%0h,\td = 0x%0h,\tTB_ans = 0x%0h;\tWRONG!", a, b, c, s, d, ans);
                $finish;
            end else begin
                $display("a = 0x%0h,\tb = 0x%0h,\tc = 0x%0h,\ts = 0x%0h,\td = 0x%0h,\tTB_ans = 0x%0h;\tCORRECT!", a, b, c, s, d, ans);
            end
        end
    end
endmodule
