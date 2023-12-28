module HW4 (
    input   [482*3*8-1 : 0]   img_data_padding_flatten,
    input                       ready,
    output  [480*8-1 : 0]   result_x_flatten,
    output  [480*8-1 : 0]   result_y_flatten
);
    // Input image data
    reg     [7:0]               img_data_padding    [0 : 482*3 - 1];

    // Output gradient data
    reg     [7:0]               result_gx           [0:480-1];
    reg     [7:0]               result_gy           [0:480-1];
    reg     [480*8-1 : 0]   buffer_x;
    reg     [480*8-1 : 0]   buffer_y;
    integer                     gx;
    integer                     gy;
    integer                     i;
    integer                     j;

    // ----------------------------------------------------------------
    reg     [7:0]               line_buffer         [482*2 + 3 - 1 : 0];
    integer                     index;
    // ----------------------------------------------------------------

    assign result_x_flatten = buffer_x;
    assign result_y_flatten = buffer_y;

    always @(*) begin
        if (ready) begin
            // 1d -> 2d
            for (i = 0; i < 482*3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    img_data_padding[i][j] = img_data_padding_flatten[i * 8 + j];
                end
            end

            // initialize line_buffer
            for (i=0; i<482*2+3; i=i+1) begin
                line_buffer[i] = img_data_padding[i];
            end

            index = 0;
            while (index < 480) begin
                gx = -line_buffer[0] + line_buffer[2]
                     - 2*line_buffer[482] + 2*line_buffer[484]
                     - line_buffer[964] + line_buffer[966];

                gy = line_buffer[0] + 2*line_buffer[1] + line_buffer[2]
                    - line_buffer[964] - 2*line_buffer[965] - line_buffer[966];

                result_gx[index] = (gx > 100) ? 255 : 0;
                result_gy[index] = (gy > 100) ? 255 : 0;

                for (i=1; i<482*2+3; i=i+1) begin
                    line_buffer[i-1] = line_buffer[i];
                end
                line_buffer[966] = img_data_padding[index + 966];
                index = index + 1;
            end

            // 2d -> 1d
            for (i = 0; i < 480; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    buffer_x[i * 8 + j] = result_gx[i][j];
                    buffer_y[i * 8 + j] = result_gy[i][j];
                end
            end
        end
    end
endmodule
