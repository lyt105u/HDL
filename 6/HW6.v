module HW6 (
    input                               clk,
    input                               reset,
    input                               ready,
    input signed    [(58*2+3)*9-1:0]   line_buffer1_flatten,
    input signed    [(58*2+3)*9-1:0]   line_buffer2_flatten,
    input signed    [(58*2+3)*9-1:0]   line_buffer3_flatten,
    input signed    [3*3*3*16-1:0]      kernel_flatten,
    input signed    [15:0]              bias_flatten,
    input signed    [8:0]               data_in1,
    input signed    [8:0]               data_in2,
    input signed    [8:0]               data_in3,
    output signed   [35:0]              output_result
);
    reg signed  [15:0]  kernel          [0:3*3*3-1];
    reg signed  [15:0]  bias;
    reg signed  [8:0]   line_buffer1    [58*2+3-1:0];
    reg signed  [8:0]   line_buffer2    [58*2+3-1:0];
    reg signed  [8:0]   line_buffer3    [58*2+3-1:0];

    reg signed [35:0] buffer1;
    reg signed [35:0] buffer2;
    reg signed [35:0] buffer3;

    integer i, i1, i2, i3;
    integer j;
    integer input_idx1, input_idx2, input_idx3;

    assign output_result = buffer1 + buffer2 + buffer3;

    always @(posedge clk) begin
        if (reset) begin
            input_idx1 = 0;
            input_idx2 = 0;
            input_idx3 = 0;

            for (i = 0; i < 3*3*3; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    kernel[i][j] = kernel_flatten[i * 16 + j];
                end
            end
            bias = bias_flatten;
        end
    end

    // PE1
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 58*2+3; i = i + 1) begin
                for (j = 0; j < 9; j = j + 1) begin
                    line_buffer1[i][j] = line_buffer1_flatten[i * 9 + j];
                end
            end
        end
        if (ready) begin
            if ( (input_idx1%58)!=56 && (input_idx1%58!=57) ) begin
                // convolution
                buffer1 = (line_buffer1[0]*kernel[0] + line_buffer1[1]*kernel[1])
                        + (line_buffer1[2]*kernel[2] + line_buffer1[58]* kernel[3])
                        + (line_buffer1[59]*kernel[4] + line_buffer1[60]*kernel[5])
                        + (line_buffer1[116]*kernel[6] + line_buffer1[117]*kernel[7])
                        + line_buffer1[118]*kernel[8];
                // add bias
                buffer1 = buffer1 + bias;

                // ReLU
                if(buffer1 < 0) begin
                    buffer1 = 0;
                end
            end else begin
                buffer1 = 36'bx;
            end

            for (i1=1; i1<58*2+3; i1=i1+1) begin
                line_buffer1[i1-1] = line_buffer1[i1];
            end
            input_idx1 = input_idx1 + 1;
            line_buffer1[118] = data_in1;
        end
    end

    // PE2
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 58*2+3; i = i + 1) begin
                for (j = 0; j < 9; j = j + 1) begin
                    line_buffer2[i][j] = line_buffer2_flatten[i * 9 + j];
                end
            end
        end
        if (ready) begin
            if ( (input_idx2%58)!=56 && (input_idx2%58!=57) ) begin
                // convolution
                buffer2 = (line_buffer2[0]*kernel[9] + line_buffer2[1]*kernel[10])
                        + (line_buffer2[2]*kernel[11] + line_buffer2[58]* kernel[12])
                        + (line_buffer2[59]*kernel[13] + line_buffer2[60]*kernel[14])
                        + (line_buffer2[116]*kernel[15] + line_buffer2[117]*kernel[16])
                        + line_buffer2[118]*kernel[17];
                // add bias
                buffer2 = buffer2 + bias;

                // ReLU
                if(buffer2 < 0) begin
                    buffer2 = 0;
                end
            end else begin
                buffer2 = 36'bx;
            end

            for (i2=1; i2<58*2+3; i2=i2+1) begin
                line_buffer2[i2-1] = line_buffer2[i2];
            end
            input_idx2 = input_idx2 + 1;
            line_buffer2[118] = data_in2;
        end
    end

    // PE3
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 58*2+3; i = i + 1) begin
                for (j = 0; j < 9; j = j + 1) begin
                    line_buffer3[i][j] = line_buffer3_flatten[i * 9 + j];
                end
            end
        end
        if (ready) begin
            if ( (input_idx3%58)!=56 && (input_idx3%58!=57) ) begin
                // convolution
                buffer3 = (line_buffer3[0]*kernel[18] + line_buffer3[1]*kernel[19])
                        + (line_buffer3[2]*kernel[20] + line_buffer3[58]* kernel[21])
                        + (line_buffer3[59]*kernel[22] + line_buffer3[60]*kernel[23])
                        + (line_buffer3[116]*kernel[24] + line_buffer3[117]*kernel[25])
                        + line_buffer3[118]*kernel[26];
                // add bias
                buffer3 = buffer3 + bias;

                // ReLU
                if(buffer3 < 0) begin
                    buffer3 = 0;
                end
            end else begin
                buffer3 = 36'bx;
            end

            for (i3=1; i3<58*2+3; i3=i3+1) begin
                line_buffer3[i3-1] = line_buffer3[i3];
            end
            input_idx3 = input_idx3 + 1;
            line_buffer3[118] = data_in3;
        end
    end
endmodule
