`timescale 1ns / 1ns
`define period          6
`define path_img_in     "./cat224.bmp"

module HDL_HW5_TB;
    integer img_in;
    // integer img_h;  // 224
    // integer img_w;  // 224
    // integer header; // 54

    reg                         clk;
    reg                         reset;
    reg                         ready;
    reg                         lyr1_flag;
    reg     [7:0]               img_data            [0 : 224*224*3 + 54 - 1];
    reg     [7:0]               img_R               [0 : 224*224 - 1];
    reg     [7:0]               img_G               [0 : 224*224 - 1];
    reg     [7:0]               img_B               [0 : 224*224 - 1];
    reg     [15:0]              lyr1_kernel         [0 : 3*3*3*64 - 1];
    reg     [3*3*4*16-1:0]      kernel_flatten;
    reg     [15:0]              lyr1_bias           [0 : 63];
    reg     [15:0]              bias_flatten;
    reg     [100*8:1]           line;   // img_Buffer to store each line
    reg     [8:0]               lyr_input          [0:3][0 : 226*226 - 1];
    reg     [(226*2+3)*9-1:0]   line_buffer1_flatten;
    reg     [(226*2+3)*9-1:0]   line_buffer2_flatten;
    reg     [(226*2+3)*9-1:0]   line_buffer3_flatten;
    reg     [(226*2+3)*9-1:0]   line_buffer4_flatten;
    reg     [7:0]               lyr1_output         [0:224*224-1];
    reg     [8:0]               lyr2_input          [0:63][0 : 226*226 - 1];
    reg     [15:0]              lyr2_kernel         [0 : 3*3*64*64 - 1];
    reg     [15:0]              lyr2_bias           [0 : 63];
    reg     [7:0]               lyr2_output         [0:224*224-1];
    reg     [35:0]              lyr2_output_total   [0:224*224-1];

    wire    [35:0] output_result;

    integer txt1_bias, txt1_kernel, txt2_bias, txt2_kernel;
    integer r, i, j, idx, result_idx;
    integer img_out_x;
    integer img_cnt, round;

    HW5 HW5 (
        clk,
        reset,
        ready,
        lyr1_flag,
        line_buffer1_flatten,
        line_buffer2_flatten,
        line_buffer3_flatten,
        line_buffer4_flatten,
        kernel_flatten,
        bias_flatten,
        lyr_input[0][idx],
        lyr_input[1][idx],
        lyr_input[2][idx],
        lyr_input[3][idx],
        output_result
    );

    always begin
		#(`period/2.0) clk <= ~clk;
	end

    initial begin
        clk = 1'b1;
        reset = 0;
        ready = 0;

        // ---------------------------------------- layer 1 ----------------------------------------
        $display("processing layer 1......");

        // read image
        img_in  = $fopen(`path_img_in, "rb");
        $fread(img_data, img_in);
        for (i = 0; i < 224*224; i = i + 1) begin
            img_B[i] = img_data[3*i + 54];
            img_G[i] = img_data[3*i + 1 + 54];
            img_R[i] = img_data[3*i + 2 + 54];
        end
        #(`period)
        $fclose(img_in);

        // add padding
        for (j = 0; j < 226; j = j + 1) begin
            for (i = 0; i < 226; i = i + 1) begin
                if (i == 0 || i == 225 || j == 0 || j == 225) begin
                    lyr_input[0][i + j * 226] = 9'b0;
                    lyr_input[1][i + j * 226] = 9'b0;
                    lyr_input[2][i + j * 226] = 9'b0;
                    lyr_input[3][i + j * 226] = 9'b0;
                    // $write("%d ", lyr_input[i + j *226]);
                end else begin
                    lyr_input[0][i + j * 226] = {1'd0, img_B[(i - 1) + (j - 1) * 224]};
                    lyr_input[1][i + j * 226] = {1'd0, img_G[(i - 1) + (j - 1) * 224]};
                    lyr_input[2][i + j * 226] = {1'd0, img_R[(i - 1) + (j - 1) * 224]};
                    lyr_input[3][i + j * 226] = 9'b0;
                    // $write("%d ", lyr_input[i + j *226]);
                end
            end
            // $write("\n");
        end

        // flatten line buffer
        // line buffer contains the first 226*2+3 elements of lyr_input
        for (i = 0; i < 226*2+3; i = i + 1) begin
            for (j = 0; j < 9; j = j + 1) begin
                line_buffer1_flatten[i*9 + j] = lyr_input[0][i][j];
                line_buffer2_flatten[i*9 + j] = lyr_input[1][i][j];
                line_buffer3_flatten[i*9 + j] = lyr_input[2][i][j];
                line_buffer4_flatten[i*9 + j] = 1'b0;
            end
        end

        // read layer 1 kernel
        txt1_kernel = $fopen("conv1_kernel_hex.txt", "r");
        if (txt1_kernel == 0) begin
            $display("Failed to open file.");
            $finish;
        end
        i = 0;
        while (!$feof(txt1_kernel) && i < 3*3*3*64) begin
            r = $fgets(line, txt1_kernel);
            if (r != 0) begin
                $sscanf(line, "%h", lyr1_kernel[i]);
                // $display("%b", lyr1_kernel[i]);
                i = i + 1;
            end
        end
        #(`period)
        $fclose(txt1_kernel);

        // read layer 1 bias
        txt1_bias = $fopen("conv1_bias_hex.txt", "r");
        if (txt1_bias == 0) begin
            $display("Failed to open file.");
            $finish;
        end
        i = 0;
        while (!$feof(txt1_bias) && i < 64) begin
            r = $fgets(line, txt1_bias);
            if (r != 0) begin
                $sscanf(line, "%h", lyr1_bias[i]);
                // $display("%b", lyr1_bias[i]);
                i = i + 1;
            end
        end
        #(`period)
        $fclose(txt1_bias);

        lyr1_flag = 1;

        for (img_cnt=0; img_cnt < 64; img_cnt=img_cnt+1) begin
            // flatten layer 1 kernel
            for (i = 0; i < 3*3*3; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    kernel_flatten[i*16 + j] = lyr1_kernel[i+img_cnt*27][j];
                end
            end
            // only three channels, so set the forth one to zero
            for (i = 3*3*3; i < 3*3*4; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    kernel_flatten[i*16 + j] = 1'b0;
                end
            end

            // flatten layer 1 bias
            bias_flatten = lyr1_bias[img_cnt];

            // HW5 reset
            #(`period)
            reset = 1;
            #(`period)
            reset = 0;

            // HW5 do line buffer and convolution
            idx = 455;
            result_idx = 0;
            while (idx < 226*226) begin
                #(`period)
                ready = 1;
                #(`period)
                ready = 0;
                idx = idx + 1;

                // if got unknown value, means the line buffer keeps rolling without doing anything
                // got result, store it in lyr1_output
                if(output_result[0] !== 1'bx) begin
                    for (i=0; i<8; i=i+1) begin
                        lyr1_output[result_idx][i] = output_result[i+5];
                    end
                    result_idx = result_idx + 1;
                end
            end

            // img_out_x = $fopen("./lyr1_1.bmp", "wb");
            case (img_cnt+1)
                1: img_out_x = $fopen("./lyr1_1.bmp", "wb");
                2: img_out_x = $fopen("./lyr1_2.bmp", "wb");
                3: img_out_x = $fopen("./lyr1_3.bmp", "wb");
                4: img_out_x = $fopen("./lyr1_4.bmp", "wb");
                5: img_out_x = $fopen("./lyr1_5.bmp", "wb");
                6: img_out_x = $fopen("./lyr1_6.bmp", "wb");
                7: img_out_x = $fopen("./lyr1_7.bmp", "wb");
                8: img_out_x = $fopen("./lyr1_8.bmp", "wb");
                9: img_out_x = $fopen("./lyr1_9.bmp", "wb");
                10: img_out_x = $fopen("./lyr1_10.bmp", "wb");
                11: img_out_x = $fopen("./lyr1_11.bmp", "wb");
                12: img_out_x = $fopen("./lyr1_12.bmp", "wb");
                13: img_out_x = $fopen("./lyr1_13.bmp", "wb");
                14: img_out_x = $fopen("./lyr1_14.bmp", "wb");
                15: img_out_x = $fopen("./lyr1_15.bmp", "wb");
                16: img_out_x = $fopen("./lyr1_16.bmp", "wb");
                17: img_out_x = $fopen("./lyr1_17.bmp", "wb");
                18: img_out_x = $fopen("./lyr1_18.bmp", "wb");
                19: img_out_x = $fopen("./lyr1_19.bmp", "wb");
                20: img_out_x = $fopen("./lyr1_20.bmp", "wb");
                21: img_out_x = $fopen("./lyr1_21.bmp", "wb");
                22: img_out_x = $fopen("./lyr1_22.bmp", "wb");
                23: img_out_x = $fopen("./lyr1_23.bmp", "wb");
                24: img_out_x = $fopen("./lyr1_24.bmp", "wb");
                25: img_out_x = $fopen("./lyr1_25.bmp", "wb");
                26: img_out_x = $fopen("./lyr1_26.bmp", "wb");
                27: img_out_x = $fopen("./lyr1_27.bmp", "wb");
                28: img_out_x = $fopen("./lyr1_28.bmp", "wb");
                29: img_out_x = $fopen("./lyr1_29.bmp", "wb");
                30: img_out_x = $fopen("./lyr1_30.bmp", "wb");
                31: img_out_x = $fopen("./lyr1_31.bmp", "wb");
                32: img_out_x = $fopen("./lyr1_32.bmp", "wb");
                33: img_out_x = $fopen("./lyr1_33.bmp", "wb");
                34: img_out_x = $fopen("./lyr1_34.bmp", "wb");
                35: img_out_x = $fopen("./lyr1_35.bmp", "wb");
                36: img_out_x = $fopen("./lyr1_36.bmp", "wb");
                37: img_out_x = $fopen("./lyr1_37.bmp", "wb");
                38: img_out_x = $fopen("./lyr1_38.bmp", "wb");
                39: img_out_x = $fopen("./lyr1_39.bmp", "wb");
                40: img_out_x = $fopen("./lyr1_40.bmp", "wb");
                41: img_out_x = $fopen("./lyr1_41.bmp", "wb");
                42: img_out_x = $fopen("./lyr1_42.bmp", "wb");
                43: img_out_x = $fopen("./lyr1_43.bmp", "wb");
                44: img_out_x = $fopen("./lyr1_44.bmp", "wb");
                45: img_out_x = $fopen("./lyr1_45.bmp", "wb");
                46: img_out_x = $fopen("./lyr1_46.bmp", "wb");
                47: img_out_x = $fopen("./lyr1_47.bmp", "wb");
                48: img_out_x = $fopen("./lyr1_48.bmp", "wb");
                49: img_out_x = $fopen("./lyr1_49.bmp", "wb");
                50: img_out_x = $fopen("./lyr1_50.bmp", "wb");
                51: img_out_x = $fopen("./lyr1_51.bmp", "wb");
                52: img_out_x = $fopen("./lyr1_52.bmp", "wb");
                53: img_out_x = $fopen("./lyr1_53.bmp", "wb");
                54: img_out_x = $fopen("./lyr1_54.bmp", "wb");
                55: img_out_x = $fopen("./lyr1_55.bmp", "wb");
                56: img_out_x = $fopen("./lyr1_56.bmp", "wb");
                57: img_out_x = $fopen("./lyr1_57.bmp", "wb");
                58: img_out_x = $fopen("./lyr1_58.bmp", "wb");
                59: img_out_x = $fopen("./lyr1_59.bmp", "wb");
                60: img_out_x = $fopen("./lyr1_60.bmp", "wb");
                61: img_out_x = $fopen("./lyr1_61.bmp", "wb");
                62: img_out_x = $fopen("./lyr1_62.bmp", "wb");
                63: img_out_x = $fopen("./lyr1_63.bmp", "wb");
                64: img_out_x = $fopen("./lyr1_64.bmp", "wb");
                default: img_out_x = 0;
            endcase

            for(i = 0; i < 54; i = i + 1) begin
                $fwrite(img_out_x, "%c", img_data[i]);
            end
            #(`period)
            for(i = 0; i < 224*224; i = i+1) begin
                $fwrite(img_out_x, "%c%c%c", lyr1_output[i], lyr1_output[i], lyr1_output[i]);
                // #(`period);
            end
            #(`period)
            $fclose(img_out_x);
            $display("lyr1_%d.bmp generated", img_cnt+1);

            // add padding, store in lyr2_input
            for (j = 0; j < 226; j = j + 1) begin
                for (i = 0; i < 226; i = i + 1) begin
                    if (i == 0 || i == 225 || j == 0 || j == 225) begin
                        lyr2_input[img_cnt][i + j * 226] = 9'b0;
                        // $write("%d ", lyr2_input[img_cnt][i + j *226]);
                    end else begin
                        lyr2_input[img_cnt][i + j * 226] = {1'd0, lyr1_output[(i - 1) + (j - 1) * 224]};
                        // $write("%d ", lyr2_input[img_cnt][i + j *226]);
                    end
                end
                // $write("\n");
            end
        end

        // ---------------------------------------- layer 2 ----------------------------------------
        $display("processing layer 2......");
        lyr1_flag = 0;

        // read layer 2 kernel
        txt2_kernel = $fopen("conv2_kernel_hex.txt", "r");
        if (txt2_kernel == 0) begin
            $display("Failed to open file.");
            $finish;
        end
        i = 0;
        while (!$feof(txt2_kernel) && i < 3*3*64*64) begin
            r = $fgets(line, txt2_kernel);
            if (r != 0) begin
                $sscanf(line, "%h", lyr2_kernel[i]);
                // $display("%b", lyr2_kernel[i]);
                i = i + 1;
            end
        end
        #(`period)
        $fclose(txt2_kernel);

        // read layer 2 bias
        txt2_bias = $fopen("conv1_bias_hex.txt", "r");
        if (txt2_bias == 0) begin
            $display("Failed to open file.");
            $finish;
        end
        i = 0;
        while (!$feof(txt2_bias) && i < 64) begin
            r = $fgets(line, txt2_bias);
            if (r != 0) begin
                $sscanf(line, "%h", lyr2_bias[i]);
                // $display("%b", lyr1_bias[i]);
                i = i + 1;
            end
        end
        #(`period)
        $fclose(txt2_bias);

        for (img_cnt=0; img_cnt < 64; img_cnt=img_cnt+1) begin
            // flatten layer 2 bias
            bias_flatten = lyr2_bias[img_cnt];

            // initialize lyr2_output_total
            for (i=0; i<224*224; i=i+1) begin
                lyr2_output_total[i] = 36'b0;
            end

            // 64 channels in total, and each round uses 4 channel => 16 rounds
            for (round=0; round<16; round=round+1) begin
                // flatten layer 2 kernel
                for (i = 0; i < 3*3*4; i = i + 1) begin
                    for (j = 0; j < 16; j = j + 1) begin
                        kernel_flatten[i*16 + j] = lyr2_kernel[i+img_cnt*576+round*36][j];
                    end
                end
                
                // store lyr_input
                for (i=0; i<226*226; i=i+1) begin
                    lyr_input[0][i] = lyr2_input[round*4][i];
                    lyr_input[1][i] = lyr2_input[round*4+1][i];
                    lyr_input[2][i] = lyr2_input[round*4+2][i];
                    lyr_input[3][i] = lyr2_input[round*4+3][i];
                end

                // flatten line buffer
                for (i = 0; i < 226*2+3; i = i + 1) begin
                    for (j = 0; j < 9; j = j + 1) begin
                        line_buffer1_flatten[i*9 + j] = lyr_input[0][i][j];
                        line_buffer2_flatten[i*9 + j] = lyr_input[1][i][j];
                        line_buffer3_flatten[i*9 + j] = lyr_input[2][i][j];
                        line_buffer4_flatten[i*9 + j] = lyr_input[3][i][j];
                    end
                end

                // HW5 reset
                #(`period)
                reset = 1;
                #(`period)
                reset = 0;

                // HW5 do line buffer and convolution
                idx = 455;
                result_idx = 0;
                while (idx < 226*226) begin
                    #(`period)
                    ready = 1;
                    #(`period)
                    ready = 0;
                    idx = idx + 1;

                    // if got unknown value, means the line buffer keeps rolling without doing anything
                    // got result, store it in lyr2_output
                    if(output_result[0] !== 1'bx) begin
                        lyr2_output_total[result_idx] = lyr2_output_total[result_idx] + output_result;
                        result_idx = result_idx + 1;
                    end
                end
            end

            for (i=0; i<224*224; i=i+1) begin
                for (j=0; j<8; j=j+1) begin
                    lyr2_output[i][j] = lyr2_output_total[i][j+7];
                end
            end

            case (img_cnt+1)
                1: img_out_x = $fopen("./lyr2_1.bmp", "wb");
                2: img_out_x = $fopen("./lyr2_2.bmp", "wb");
                3: img_out_x = $fopen("./lyr2_3.bmp", "wb");
                4: img_out_x = $fopen("./lyr2_4.bmp", "wb");
                5: img_out_x = $fopen("./lyr2_5.bmp", "wb");
                6: img_out_x = $fopen("./lyr2_6.bmp", "wb");
                7: img_out_x = $fopen("./lyr2_7.bmp", "wb");
                8: img_out_x = $fopen("./lyr2_8.bmp", "wb");
                9: img_out_x = $fopen("./lyr2_9.bmp", "wb");
                10: img_out_x = $fopen("./lyr2_10.bmp", "wb");
                11: img_out_x = $fopen("./lyr2_11.bmp", "wb");
                12: img_out_x = $fopen("./lyr2_12.bmp", "wb");
                13: img_out_x = $fopen("./lyr2_13.bmp", "wb");
                14: img_out_x = $fopen("./lyr2_14.bmp", "wb");
                15: img_out_x = $fopen("./lyr2_15.bmp", "wb");
                16: img_out_x = $fopen("./lyr2_16.bmp", "wb");
                17: img_out_x = $fopen("./lyr2_17.bmp", "wb");
                18: img_out_x = $fopen("./lyr2_18.bmp", "wb");
                19: img_out_x = $fopen("./lyr2_19.bmp", "wb");
                20: img_out_x = $fopen("./lyr2_20.bmp", "wb");
                21: img_out_x = $fopen("./lyr2_21.bmp", "wb");
                22: img_out_x = $fopen("./lyr2_22.bmp", "wb");
                23: img_out_x = $fopen("./lyr2_23.bmp", "wb");
                24: img_out_x = $fopen("./lyr2_24.bmp", "wb");
                25: img_out_x = $fopen("./lyr2_25.bmp", "wb");
                26: img_out_x = $fopen("./lyr2_26.bmp", "wb");
                27: img_out_x = $fopen("./lyr2_27.bmp", "wb");
                28: img_out_x = $fopen("./lyr2_28.bmp", "wb");
                29: img_out_x = $fopen("./lyr2_29.bmp", "wb");
                30: img_out_x = $fopen("./lyr2_30.bmp", "wb");
                31: img_out_x = $fopen("./lyr2_31.bmp", "wb");
                32: img_out_x = $fopen("./lyr2_32.bmp", "wb");
                33: img_out_x = $fopen("./lyr2_33.bmp", "wb");
                34: img_out_x = $fopen("./lyr2_34.bmp", "wb");
                35: img_out_x = $fopen("./lyr2_35.bmp", "wb");
                36: img_out_x = $fopen("./lyr2_36.bmp", "wb");
                37: img_out_x = $fopen("./lyr2_37.bmp", "wb");
                38: img_out_x = $fopen("./lyr2_38.bmp", "wb");
                39: img_out_x = $fopen("./lyr2_39.bmp", "wb");
                40: img_out_x = $fopen("./lyr2_40.bmp", "wb");
                41: img_out_x = $fopen("./lyr2_41.bmp", "wb");
                42: img_out_x = $fopen("./lyr2_42.bmp", "wb");
                43: img_out_x = $fopen("./lyr2_43.bmp", "wb");
                44: img_out_x = $fopen("./lyr2_44.bmp", "wb");
                45: img_out_x = $fopen("./lyr2_45.bmp", "wb");
                46: img_out_x = $fopen("./lyr2_46.bmp", "wb");
                47: img_out_x = $fopen("./lyr2_47.bmp", "wb");
                48: img_out_x = $fopen("./lyr2_48.bmp", "wb");
                49: img_out_x = $fopen("./lyr2_49.bmp", "wb");
                50: img_out_x = $fopen("./lyr2_50.bmp", "wb");
                51: img_out_x = $fopen("./lyr2_51.bmp", "wb");
                52: img_out_x = $fopen("./lyr2_52.bmp", "wb");
                53: img_out_x = $fopen("./lyr2_53.bmp", "wb");
                54: img_out_x = $fopen("./lyr2_54.bmp", "wb");
                55: img_out_x = $fopen("./lyr2_55.bmp", "wb");
                56: img_out_x = $fopen("./lyr2_56.bmp", "wb");
                57: img_out_x = $fopen("./lyr2_57.bmp", "wb");
                58: img_out_x = $fopen("./lyr2_58.bmp", "wb");
                59: img_out_x = $fopen("./lyr2_59.bmp", "wb");
                60: img_out_x = $fopen("./lyr2_60.bmp", "wb");
                61: img_out_x = $fopen("./lyr2_61.bmp", "wb");
                62: img_out_x = $fopen("./lyr2_62.bmp", "wb");
                63: img_out_x = $fopen("./lyr2_63.bmp", "wb");
                64: img_out_x = $fopen("./lyr2_64.bmp", "wb");
                default: img_out_x = 0;
            endcase

            for(i = 0; i < 54; i = i + 1) begin
                $fwrite(img_out_x, "%c", img_data[i]);
            end
            #(`period)
            for(i = 0; i < 224*224; i = i+1) begin
                $fwrite(img_out_x, "%c%c%c", lyr2_output[i], lyr2_output[i], lyr2_output[i]);
                // #(`period);
            end
            #(`period)
            $fclose(img_out_x);
            $display("lyr2_%d.bmp generated", img_cnt+1);
        end

        $stop;
    end
endmodule
