`timescale 1ns / 1ns
`define period          10
`define img_max_size    480*360*3+54
`define img_gray_max_size    480*360*3+54
`define img_padding_max_size    482*362
`define path_img_in     "./cat.bmp"
`define path_img_gray   "./cat_gray.bmp"
`define path_img_x   "./cat_x.bmp"
`define path_img_y   "./cat_y.bmp"

module HDL_HW4_TB;
    integer img_in;
    integer img_out_gray;
    integer img_in_gray;
    // integer img_out_padding;
    integer img_out_x;
    integer img_out_y;
    integer offset;
    integer img_h;
    integer img_w;
    integer idx;
    integer header;

    integer i, j, k;
    reg     ready;

    reg         clk;
    reg  [7:0]  img_data [0:`img_max_size-1];
    reg  [7:0]  img_data_gray [0:`img_gray_max_size-1];
    reg  [7:0]  img_data_padding [0:`img_padding_max_size-1];
    reg  [7:0]  img_data_x [0:480*360-1];
    reg  [7:0]  img_data_y [0:480*360-1]; 
    reg  [7:0]  R;
    reg  [7:0]  G;
    reg  [7:0]  B;
    wire [19:0] Y;

    reg     [482*362*8 - 1 : 0] img_data_padding_flatten;
    reg     [482*3*8 -1 : 0] input_flatten;
    wire    [480*8 - 1 : 0] output_x_flatten;
    wire    [480*8 - 1 : 0] output_y_flatten;

    // Insert your  verilog module at here
    HW4 HW4 (
        input_flatten,
        ready,
        output_x_flatten,
        output_y_flatten
    );

//---------------------------------------------------------------------------------------Take out the color image(cat) of RGB----------------------------------------------
    // gray-scale conversion
    assign Y = 0.21 * R + 0.72 * G + 0.07 * B;

    always begin
		#(`period/2.0) clk <= ~clk;
	end

    // reading image data
    initial begin
        img_in  = $fopen(`path_img_in, "rb");
        img_out_gray = $fopen(`path_img_gray, "wb");

        $fread(img_data, img_in);

        img_w   = {img_data[21],img_data[20],img_data[19],img_data[18]};
        img_h   = {img_data[25],img_data[24],img_data[23],img_data[22]};
        offset  = {img_data[13],img_data[12],img_data[11],img_data[10]};

        for(header = 0; header < 54; header = header + 1) begin
			$fwrite(img_out_gray, "%c", img_data[header]);
        end
    end

    // image processing
    initial begin
        clk = 1'b1;
        ready = 0;
        #(`period)
        for(idx = 0; idx < img_h*img_w; idx = idx+1) begin
            R <= img_data[idx*3 + offset + 2];
            G <= img_data[idx*3 + offset + 1];
            B <= img_data[idx*3 + offset + 0];
            
            // Write grayscale value to all RGB channels
            $fwrite(img_out_gray, "%c%c%c", Y[7:0], Y[7:0], Y[7:0]);
            #(`period);
        end
        #(`period)
        $fclose(img_in);
        $fclose(img_out_gray);

        img_in_gray  = $fopen(`path_img_gray, "rb");
        // img_out_padding = $fopen(`path_img_padding, "wb");
        $fread(img_data_gray, img_in_gray);
        // $display("start");
        for (j = 0; j < 362; j = j + 1) begin
            for (i = 0; i < 482; i = i + 1) begin
                if (i == 0 || i == 481 || j == 0 || j == 361) begin
                    img_data_padding[i + j * 482] = 8'b0;
                    // $write("%d ", img_data_padding[i + j *482]);
                end else begin
                    img_data_padding[i + j * 482] = img_data_gray[ ((i - 1) + (j - 1) * 480) * 3 + offset];
                    // $write("%d ", img_data_padding[i + j *482]);
                end
            end
            // $write("\n");
        end

        // for(header = 0; header < 54; header = header + 1) begin
		// 	$fwrite(img_out_padding, "%c", img_data[header]);
        // end
        // #(`period)
        // for(idx = 0; idx < 482*362; idx = idx+1) begin
        //     $fwrite(img_out_padding, "%c%c%c", img_data_padding[idx], img_data_padding[idx], img_data_padding[idx]);
        //     #(`period);
        // end
        // #(`period)
        $fclose(img_in_gray);
        // $fclose(img_out_padding);


        // flatten the grayscale padding image
        for (i = 0; i < `img_padding_max_size; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                img_data_padding_flatten[i * 8 + j] = img_data_padding[i][j];
            end
        end

        // #2000000

        for (j=0; j<360; j=j+1) begin
            // choose three rows from flatten to be the input of HW4
             for (i=0; i<482*3*8; i=i+1) begin
                input_flatten[i] = img_data_padding_flatten[i + j*482*8];
             end
             ready = 1;
             #5000
             ready = 0;
             for (i=0; i<480; i=i+1) begin
                for (k=0; k<8; k=k+1) begin
                    img_data_x[i + 480*j][k] = output_x_flatten[i*8 + k];
                    img_data_y[i + 480*j][k] = output_y_flatten[i*8 + k];
                end
             end
        end

        // $display("after #2000000");

        // for (i = 0; i < 480*360; i = i + 1) begin
        //     for (j = 0; j < 8; j = j + 1) begin
        //         img_data_x[i][j] = output_x_flatten[i * 8 + j];
        //         img_data_y[i][j] = output_y_flatten[i * 8 + j];
        //     end
        //     $write("%d ", img_data_x[i]);
        // end
        // $write("\n");

        

        img_out_x = $fopen(`path_img_x, "wb");
        img_out_y = $fopen(`path_img_y, "wb");
        for(header = 0; header < 54; header = header + 1) begin
			$fwrite(img_out_x, "%c", img_data[header]);
            $fwrite(img_out_y, "%c", img_data[header]);
        end
        #(`period)
        for(idx = 0; idx < 480*360; idx = idx+1) begin
            $fwrite(img_out_x, "%c%c%c", img_data_x[idx], img_data_x[idx], img_data_x[idx]);
            $fwrite(img_out_y, "%c%c%c", img_data_y[idx], img_data_y[idx], img_data_y[idx]);
            #(`period);
        end
        #(`period)
        $fclose(img_out_x);
        $fclose(img_out_y);

        $stop;
    end

    /*
    initial begin
		$sdf_annotate (`path_sdf, <your instance name>);
	end
    */
endmodule