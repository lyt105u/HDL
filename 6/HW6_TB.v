`timescale 1ns / 1ns
`define period          10
`define img_max_size    480*360*3+54
`define cat56_size    	56*56
`define path_img_224     "./cat224.bmp"
`define path_img_56    "./cat56.bmp"

module HDL_HW6_TB;
    integer img_in;
    integer img_out;
    integer offset;
    integer img_h;
    integer img_w;
    integer idx;
	integer jdx;
	integer kdx;
    integer header;
	integer i, j, r, result_idx;
    reg         clk;
    reg         ready;
    reg         reset;
    reg  [7:0]  img_data [0:`img_max_size-1];

    reg  [11:0]  R_resize;
    reg  [11:0]  G_resize;
    reg  [11:0]  B_resize;	
    reg  [7:0]  R_56x56;
    reg  [7:0]  G_56x56;
    reg  [7:0]  B_56x56;

    reg [7:0]               img_R                   [0 : 56*56 - 1];
    reg [7:0]               img_G                   [0 : 56*56 - 1];
    reg [7:0]               img_B                   [0 : 56*56 - 1];
    reg [8:0]               lyr_input               [0:2][0 : 226*226 - 1];
    reg [(58*2+3)*9-1:0]   line_buffer1_flatten;
    reg [(58*2+3)*9-1:0]   line_buffer2_flatten;
    reg [(58*2+3)*9-1:0]   line_buffer3_flatten;
    reg [100*8:1]           line;
    reg [15:0]              lyr1_kernel             [0 : 3*3*3*64 - 1];
    reg [3*3*3*16-1:0]      kernel_flatten;
    reg [15:0]              lyr1_bias               [0 : 63];
    reg [15:0]              bias_flatten;
    reg [7:0]               lyr1_output             [0:224*224-1];

    integer txt1_bias, txt1_kernel, img_cnt, img_out_x;

    wire    [35:0] output_result;

    //Insert your verilog module here
    HW6 HW6 (
        clk,
        reset,
        ready,
        line_buffer1_flatten,
        line_buffer2_flatten,
        line_buffer3_flatten,
        kernel_flatten,
        bias_flatten,
        lyr_input[0][idx],
        lyr_input[1][idx],
        lyr_input[2][idx],
        output_result
    );

    always begin
		#(`period/2.0) clk <= ~clk;
	end

    //This initial block read the pixel 
    initial begin
        img_in  = $fopen(`path_img_224, "rb");
        img_out = $fopen(`path_img_56, "wb");

        $fread(img_data, img_in);

        img_w   = {img_data[21],img_data[20],img_data[19],img_data[18]};
        img_h   = {img_data[25],img_data[24],img_data[23],img_data[22]};
        offset  = {img_data[13],img_data[12],img_data[11],img_data[10]};
		
        for(header = 0; header < 54; header = header + 1) begin	//output header -> 56x56
			if(header==18 || header==22) 
				$fwrite(img_out, "%c", 8'd56);
			else 
				$fwrite(img_out, "%c", img_data[header]);
        end
    end

    initial begin
        clk <= 1'b1;
		R_resize<=0;
		G_resize<=0;
		B_resize<=0;
        ready <= 0;
        reset <= 0;
		
		i<=0;
		#(`period);
		//Resize  the 224x224 to 56x56
	    for(idx = 0; idx <`cat56_size; idx = idx+1) begin						
			for(jdx = (0+4*(idx/56)); jdx <(4+4*(idx/56)); jdx = jdx+1) begin
				for(kdx = (0+4*i); kdx <(4+4*i); kdx = kdx+1) begin
					R_resize <= R_resize + img_data[(kdx+(jdx*224))*3 + offset + 2];
					G_resize <= G_resize + img_data[(kdx+(jdx*224))*3 + offset + 1];
					B_resize <= B_resize + img_data[(kdx+(jdx*224))*3 + offset + 0];
					#(`period);		
				end		
			end
	
			R_56x56 <=R_resize/16;	//Take  R_56x56 as input 
			G_56x56 <=G_resize/16;	//Take  G_56x56 as input 
			B_56x56 <=B_resize/16;	//Take  B_56x56 as input 
			#(`period);
			
			//write cat56.bmp
			$fwrite(img_out, "%c%c%c",B_56x56[7:0] , G_56x56[7:0], R_56x56[7:0]);
			if(i==55)  i<=0;
			else i<=i+1;
			#(`period/2);
			R_resize <=0;
			G_resize <=0;
			B_resize <=0;
			#(`period/2);
        end	
        $fclose(img_in);
        $fclose(img_out);
        #(`period);

        // read image
        img_in  = $fopen(`path_img_56, "rb");
        $fread(img_data, img_in);
        for (i = 0; i < 56*56; i = i + 1) begin
            img_B[i] = img_data[3*i + 54];
            img_G[i] = img_data[3*i + 1 + 54];
            img_R[i] = img_data[3*i + 2 + 54];
        end
        #(`period)
        $fclose(img_in);

        // add padding
        for (j = 0; j < 58; j = j + 1) begin
            for (i = 0; i < 58; i = i + 1) begin
                if (i == 0 || i == 57 || j == 0 || j == 57) begin
                    lyr_input[0][i + j * 58] = 9'b0;
                    lyr_input[1][i + j * 58] = 9'b0;
                    lyr_input[2][i + j * 58] = 9'b0;
                    // $write("%d ", lyr_input[0][i + j *58]);
                end else begin
                    lyr_input[0][i + j * 58] = {1'd0, img_B[(i - 1) + (j - 1) * 56]};
                    lyr_input[1][i + j * 58] = {1'd0, img_G[(i - 1) + (j - 1) * 56]};
                    lyr_input[2][i + j * 58] = {1'd0, img_R[(i - 1) + (j - 1) * 56]};
                    // $write("%d ", lyr_input[0][i + j *58]);
                end
            end
            // $write("\n");
        end

        // flatten line buffer
        // line buffer contains the first 226*2+3 elements of lyr_input
        for (i = 0; i < 58*2+3; i = i + 1) begin
            for (j = 0; j < 9; j = j + 1) begin
                line_buffer1_flatten[i*9 + j] = lyr_input[0][i][j];
                line_buffer2_flatten[i*9 + j] = lyr_input[1][i][j];
                line_buffer3_flatten[i*9 + j] = lyr_input[2][i][j];
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

        for (img_cnt=0; img_cnt < 64; img_cnt=img_cnt+1) begin
            // flatten layer 1 kernel
            for (i = 0; i < 3*3*3; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    kernel_flatten[i*16 + j] = lyr1_kernel[i+img_cnt*27][j];
                end
            end

            // flatten layer 1 bias
            bias_flatten = lyr1_bias[img_cnt];

            // HW6 reset
            #(`period)
            reset = 1;
            #(`period)
            reset = 0;

            // HW6 do line buffer and convolution
            idx = 119;
            result_idx = 0;
            while (idx < 58*58) begin
                #(`period)
                ready = 1;
                #(`period)
                ready = 0;
                idx = idx + 1;

                // if got unknown value, means the line buffer keeps rolling without doing anything
                // got result, store it in lyr1_output
                if(output_result[0] !== 1'bx) begin
                    for (i=0; i<8; i=i+1) begin
                        lyr1_output[result_idx][i] = output_result[i+4];
                    end
                    result_idx = result_idx + 1;
                end
            end

            case (img_cnt+1)
                1: img_out_x = $fopen("./conv1_1.bmp", "wb");
                2: img_out_x = $fopen("./conv1_2.bmp", "wb");
                3: img_out_x = $fopen("./conv1_3.bmp", "wb");
                4: img_out_x = $fopen("./conv1_4.bmp", "wb");
                5: img_out_x = $fopen("./conv1_5.bmp", "wb");
                6: img_out_x = $fopen("./conv1_6.bmp", "wb");
                7: img_out_x = $fopen("./conv1_7.bmp", "wb");
                8: img_out_x = $fopen("./conv1_8.bmp", "wb");
                9: img_out_x = $fopen("./conv1_9.bmp", "wb");
                10: img_out_x = $fopen("./conv1_10.bmp", "wb");
                11: img_out_x = $fopen("./conv1_11.bmp", "wb");
                12: img_out_x = $fopen("./conv1_12.bmp", "wb");
                13: img_out_x = $fopen("./conv1_13.bmp", "wb");
                14: img_out_x = $fopen("./conv1_14.bmp", "wb");
                15: img_out_x = $fopen("./conv1_15.bmp", "wb");
                16: img_out_x = $fopen("./conv1_16.bmp", "wb");
                17: img_out_x = $fopen("./conv1_17.bmp", "wb");
                18: img_out_x = $fopen("./conv1_18.bmp", "wb");
                19: img_out_x = $fopen("./conv1_19.bmp", "wb");
                20: img_out_x = $fopen("./conv1_20.bmp", "wb");
                21: img_out_x = $fopen("./conv1_21.bmp", "wb");
                22: img_out_x = $fopen("./conv1_22.bmp", "wb");
                23: img_out_x = $fopen("./conv1_23.bmp", "wb");
                24: img_out_x = $fopen("./conv1_24.bmp", "wb");
                25: img_out_x = $fopen("./conv1_25.bmp", "wb");
                26: img_out_x = $fopen("./conv1_26.bmp", "wb");
                27: img_out_x = $fopen("./conv1_27.bmp", "wb");
                28: img_out_x = $fopen("./conv1_28.bmp", "wb");
                29: img_out_x = $fopen("./conv1_29.bmp", "wb");
                30: img_out_x = $fopen("./conv1_30.bmp", "wb");
                31: img_out_x = $fopen("./conv1_31.bmp", "wb");
                32: img_out_x = $fopen("./conv1_32.bmp", "wb");
                33: img_out_x = $fopen("./conv1_33.bmp", "wb");
                34: img_out_x = $fopen("./conv1_34.bmp", "wb");
                35: img_out_x = $fopen("./conv1_35.bmp", "wb");
                36: img_out_x = $fopen("./conv1_36.bmp", "wb");
                37: img_out_x = $fopen("./conv1_37.bmp", "wb");
                38: img_out_x = $fopen("./conv1_38.bmp", "wb");
                39: img_out_x = $fopen("./conv1_39.bmp", "wb");
                40: img_out_x = $fopen("./conv1_40.bmp", "wb");
                41: img_out_x = $fopen("./conv1_41.bmp", "wb");
                42: img_out_x = $fopen("./conv1_42.bmp", "wb");
                43: img_out_x = $fopen("./conv1_43.bmp", "wb");
                44: img_out_x = $fopen("./conv1_44.bmp", "wb");
                45: img_out_x = $fopen("./conv1_45.bmp", "wb");
                46: img_out_x = $fopen("./conv1_46.bmp", "wb");
                47: img_out_x = $fopen("./conv1_47.bmp", "wb");
                48: img_out_x = $fopen("./conv1_48.bmp", "wb");
                49: img_out_x = $fopen("./conv1_49.bmp", "wb");
                50: img_out_x = $fopen("./conv1_50.bmp", "wb");
                51: img_out_x = $fopen("./conv1_51.bmp", "wb");
                52: img_out_x = $fopen("./conv1_52.bmp", "wb");
                53: img_out_x = $fopen("./conv1_53.bmp", "wb");
                54: img_out_x = $fopen("./conv1_54.bmp", "wb");
                55: img_out_x = $fopen("./conv1_55.bmp", "wb");
                56: img_out_x = $fopen("./conv1_56.bmp", "wb");
                57: img_out_x = $fopen("./conv1_57.bmp", "wb");
                58: img_out_x = $fopen("./conv1_58.bmp", "wb");
                59: img_out_x = $fopen("./conv1_59.bmp", "wb");
                60: img_out_x = $fopen("./conv1_60.bmp", "wb");
                61: img_out_x = $fopen("./conv1_61.bmp", "wb");
                62: img_out_x = $fopen("./conv1_62.bmp", "wb");
                63: img_out_x = $fopen("./conv1_63.bmp", "wb");
                64: img_out_x = $fopen("./conv1_64.bmp", "wb");
                default: img_out_x = 0;
            endcase

            for(i = 0; i < 54; i = i + 1) begin
                $fwrite(img_out_x, "%c", img_data[i]);
            end
            #(`period)
            for(i = 0; i < 56*56; i = i+1) begin
                $fwrite(img_out_x, "%c%c%c", lyr1_output[i], lyr1_output[i], lyr1_output[i]);
                // #(`period);
            end
            #(`period)
            $fclose(img_out_x);
            $display("conv1_%d.bmp generated", img_cnt+1);
        end

        $finish;
    end

    /*
    initial begin
		$sdf_annotate (`path_sdf, <your instance name>);
	end
    */
endmodule
