`define SDFFILE1 "./adder_structure_between.sdf"
`define SDFFILE2 "./adder_structure_reg_between.sdf"
`define SDFFILE3 "./adder_dataflow_between.sdf"
`define SDFFILE4 "./adder_dataflow_reg_between.sdf"
`define SDFFILE5 "./adder_behavior_between.sdf"
`define SDFFILE6 "./adder_behavior_reg_between.sdf"
`timescale 1ns/1ns
module testbench;
    parameter width = 32;
    reg [width-1 : 0] a;
    reg [width-1 : 0] b;
    reg ci;
    wire [width-1 : 0] s1, s2, s3, s4, s5, s6;
    wire co1, co2, co3, co4, co5, co6;
    integer i;
    reg clk = 0;
    reg [width:0] ans;

    adder_structure fa1 (
        s1,
        co1,
        a,
        b,
        ci
    );

    adder_structure_reg fa2 (
        s2,
        co2,
        a,
        b,
        ci,
        clk
    );

    adder_dataflow fa3(
        s3,
        co3,
        a,
        b,
        ci
    );

    adder_dataflow_reg fa4 (
        s4,
        co4,
        a,
        b,
        ci,
        clk
    );

    adder_behavior fa5(
        s5,
        co5,
        a,
        b,
        ci
    );

    adder_dataflow_reg fa6 (
        s6,
        co6,
        a,
        b,
        ci,
        clk
    );

    always @(a or b or ci) begin
        ans <= a + b + ci;
    end

    initial begin
        $sdf_annotate(`SDFFILE1, fa1);
        $sdf_annotate(`SDFFILE2, fa2);
        $sdf_annotate(`SDFFILE3, fa3);
        $sdf_annotate(`SDFFILE4, fa4);
        $sdf_annotate(`SDFFILE5, fa5);
        $sdf_annotate(`SDFFILE6, fa6);

        for (i=0; i<10; i=i+1) begin
            a <= $random;
            b <= $random;
            ci <= $random;

            clk = 0;
            #20
            clk = 1;
            #20

            $display("-------------------- Round %d --------------------", i+1);
            $display("Answer:           0x%0h + 0x%0h + 0x%0h = 0x%0h", a, b, ci, ans);

            // Structural
            if (a + b + ci != {co1, s1}) begin
                $display("Structural:       0x%0h + 0x%0h + 0x%0h = 0x%0h, WRONG!", a, b, ci, {co1, s1});
                $finish;
            end else begin
                $display("Structural:       0x%0h + 0x%0h + 0x%0h = 0x%0h, CORRECT!", a, b, ci, {co1, s1});
            end

            // Structural_reg
            if (a + b + ci != {co2, s2}) begin
                $display("Structural_reg:   0x%0h + 0x%0h + 0x%0h = 0x%0h, WRONG!", a, b, ci, {co2, s2});
                $finish;
            end else begin
                $display("Structural_reg:   0x%0h + 0x%0h + 0x%0h = 0x%0h, CORRECT!", a, b, ci, {co2, s2});
            end

            // Dataflow
            if (a + b + ci != {co3, s3}) begin
                $display("Dataflow:         0x%0h + 0x%0h + 0x%0h = 0x%0h, WRONG!", a, b, ci, {co3, s3});
                $finish;
            end else begin
                $display("Dataflow:         0x%0h + 0x%0h + 0x%0h = 0x%0h, CORRECT!", a, b, ci, {co3, s3});
            end

            // Dataflow_reg
            if (a + b + ci != {co4, s4}) begin
                $display("Dataflow_reg:     0x%0h + 0x%0h + 0x%0h = 0x%0h, WRONG!", a, b, ci, {co4, s4});
                $finish;
            end else begin
                $display("Dataflow_reg:     0x%0h + 0x%0h + 0x%0h = 0x%0h, CORRECT!", a, b, ci, {co4, s4});
            end

            // Behavior
            if (a + b + ci != {co5, s5}) begin
                $display("Behavior:         0x%0h + 0x%0h + 0x%0h = 0x%0h, WRONG!", a, b, ci, {co5, s5});
                $finish;
            end else begin
                $display("Behavior:         0x%0h + 0x%0h + 0x%0h = 0x%0h, CORRECT!", a, b, ci, {co5, s5});
            end

            // Behavior_reg
            if (a + b + ci != {co6, s6}) begin
                $display("Behavior_reg:     0x%0h + 0x%0h + 0x%0h = 0x%0h, WRONG!", a, b, ci, {co6, s6});
                $finish;
            end else begin
                $display("Behavior_reg:     0x%0h + 0x%0h + 0x%0h = 0x%0h, CORRECT!", a, b, ci, {co6, s6});
            end
        end
    end
endmodule
