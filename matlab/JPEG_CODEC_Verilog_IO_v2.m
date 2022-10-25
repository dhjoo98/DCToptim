clear all
close all
clc
    %-------------------------- Initialization -----------------------------
for image_number = 1:8
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%      Get the Image data Input     %%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    input_image_512x512 = double( imread(sprintf('image_in_%d.tif',image_number),'tiff' ) );

    % Load DCT output text file from verilog (512x512 pixel)
    % Each pixel has 16bit integer data
    M = textread(sprintf('DCT_image_%d.txt',image_number),'%12c');
    M_2 = char(zeros(262144,16)); %512x512

    for i=1:262144 %for each pixel 
        M_2(i,1)= M(i,1);
        M_2(i,2)= M(i,1);
        M_2(i,3)= M(i,1);
        M_2(i,4)= M(i,1);
        M_2(i,5:16) = M(i,1:12);
    end

    DCT_image_96b = typecast(uint16(bin2dec(char(M_2))),'int16');


    x=1;
    %{
    pixel2_1hash = zeros(64,64);
    pixel1_2hash = zeros(64,64);
    for k= 1:64
        for i= 1:64  %for each 8*8 block
            for j = 1 : 8 
                if j == 1 %for column 1 
                    DCT_image( 8*(k-1)+j , 8*(i-1)+1 ) = double(DCT_image_96b(x,1)); %if row1, regard truncation
                    pixel1_2hash(k,i) = double(DCT_image_96b(x+1,1))/4;
                    DCT_image( 8*(k-1)+j , 8*(i-1)+2 ) = double(DCT_image_96b(x+1,1))/2;
                else 
                    %DCT_image( 8*(k-1)+j , 8*(i-1)+1 ) = double(DCT_image_96b(x,1))/4; %else treat like normal 
                    DCT_image( 8*(k-1)+j , 8*(i-1)+2 ) = double(DCT_image_96b(x+1,1))/4;
                    if j == 2
                        DCT_image( 8*(k-1)+j , 8*(i-1)+1 ) = double(DCT_image_96b(x,1))/2; %else treat like normal 
                        pixel2_1hash(k,i) = double(DCT_image_96b(x,1))/4;
                    else
                        DCT_image( 8*(k-1)+j , 8*(i-1)+1 ) = double(DCT_image_96b(x,1))/4; %else treat like normal 
                    end
                end 
                %DCT_image( 8*(k-1)+j , 8*(i-1)+2 ) = double(DCT_image_96b(x+1,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+3 ) = double(DCT_image_96b(x+2,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+4 ) = double(DCT_image_96b(x+3,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+5 ) = double(DCT_image_96b(x+4,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+6 ) = double(DCT_image_96b(x+5,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+7 ) = double(DCT_image_96b(x+6,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+8 ) = double(DCT_image_96b(x+7,1))/4;
                x = x+8;
            end
        end
    end
    %}
    for k= 1:64
        for i= 1:64
            for j = 1 : 8
                if j == 1
                    DCT_image( 8*(k-1)+j , 8*(i-1)+1 ) = double(DCT_image_96b(x,1));
                else
                    DCT_image( 8*(k-1)+j , 8*(i-1)+1 ) = double(DCT_image_96b(x,1))/4;
                end
                DCT_image( 8*(k-1)+j , 8*(i-1)+2 ) = double(DCT_image_96b(x+1,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+3 ) = double(DCT_image_96b(x+2,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+4 ) = double(DCT_image_96b(x+3,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+5 ) = double(DCT_image_96b(x+4,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+6 ) = double(DCT_image_96b(x+5,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+7 ) = double(DCT_image_96b(x+6,1))/4;
                DCT_image( 8*(k-1)+j , 8*(i-1)+8 ) = double(DCT_image_96b(x+7,1))/4;
                x = x+8;
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%    Cut the image for process Convenience   %%%%%
    %%%%%            and get the image data          %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [m,n] = size(DCT_image);

    m = floor(m/8)*8;
    n = floor(n/8)*8;

          %---------------------Quatization bit setup-----------------------------
            % The number of bits for DCT Coefficient Quantization
            % You can "adjust this number" to improve the qualities of images.
            C_quantization_bit =  10;                          
            T = func_DCT_Coefficient_quant(C_quantization_bit);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%        DCT Quantization Matix        %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Q_pre=[16   11  10  16    24    40     51    61; % (1,1) value (16) should be changed according to the truncation point
           12  12  14  19    26    58     60    55;
           14  13  16  24    40    57     69    56;
           14  17  22  29    51    87     80    62;
           18  22  37  56    68    109    103   77;
           24  35  55  64    81    104    113   92;
           49  64  78  87    103   121    120   101;
           72  92  95  98    112   100    103   99];

    Q   =[16  11  10  16    24    40     51    61;
          12  12  14  19    26    58     60    55;
          14  13  16  24    40    57     69    56;
          14  17  22  29    51    87     80    62;
          18  22  37  56    68    109    103   77;
          24  35  55  64    81    104    113   92;
          49  64  78  87    103   121    120   101;
          72  92  95  98    112   100    103   99];

    %--------------------------- DCT OPERATION -------------------------------

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%    2-D DCT Matrix Multiplication     %%%%%%%%%%%%%% 
    %%%%%%%%  Multiplication with Quantization Matrix   %%%%%%%%%%
    %%%%%%%%%%%%%%%%       ROUND  OFF        %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Image_tran_2 = zeros(m,n);

        for i=1:m/8
            for j=1:n/8
                Block_DCT = (DCT_image((8*i-7):8*i,(8*j-7):8*j));
                Block_r = round(Q_pre.\Block_DCT);
                Image_tran_2((8*i-7):8*i,(8*j-7):8*j) = Block_r;
            end
        end
     %------------------------------------------------------------------------


    %--------------------------- ENTROPY ENCODING ----------------------------------

        ZigZag_Order = uint8([
                                1  9  2  3  10 17 25 18
                                11 4  5  12 19 26 33 41
                                34 27 20 13 6  7  14 21 
                                28 35 42 49 57 50 43 36 
                                29 22 15 8  16 23 30 37
                                44 51 58 59 52 45 38 31 
                                24 32 39 46 53 60 61 54 
                                47 40 48 55 62 63 56 64
                              ]);


        % Break 8x8 block into columns
        Single_column_quantized_image=im2col(Image_tran_2, [8 8],'distinct');

        %--------------------------- zigzag ----------------------------------
        % using the MatLab Matrix indexing power (specially the ':' operator) rather than any function
        ZigZaged_Single_Column_Image=Single_column_quantized_image(ZigZag_Order,:);    
        %---------------------------------------------------------------------


        %---------------------- Run Level Coding -----------------------------
        % construct Run Level Pair from ZigZaged_Single_Column_Image
        run_level_pairs=int16([]);

        for block_index=1:4096    %block by block - total 256 blocks (8x8) in the 128x128 image
            single_block_image_vector_64(1:64)=0;
            for Temp_Vector_Index=1:64
                single_block_image_vector_64(Temp_Vector_Index) = ZigZaged_Single_Column_Image(Temp_Vector_Index, block_index);  %select 1 block sequentially from the ZigZaged_Single_Column_Image
            end
            non_zero_value_index_array = find(single_block_image_vector_64~=0); % index array of next non-zero entry in a block

            if isempty(find(single_block_image_vector_64~=0)) == 1
                non_zero_value_index_array(1) = 0;
            end


            number_of_non_zero_entries = length(non_zero_value_index_array);  % # of non-zero entries in a block

        % Case 1: if first ac coefficient has no leading zeros then encode first coefficient
            if non_zero_value_index_array(1)==0
                run_level_pairs=cat(1,run_level_pairs);

            elseif non_zero_value_index_array(1)==1  
               run=0;   % no leading zero
                run_level_pairs=cat(1,run_level_pairs, run, single_block_image_vector_64(non_zero_value_index_array(1)));
            end

        % Case 2: loop through each non-zero entry    
            for i=2:number_of_non_zero_entries 
                % check # of leading zeros (run)
                run=non_zero_value_index_array(i)-non_zero_value_index_array(i-1)-1;
                run_level_pairs=cat(1, run_level_pairs, run, single_block_image_vector_64(non_zero_value_index_array(i)));
            end

        % Case 3: "End of Block" mark insertion
            run_level_pairs=cat(1, run_level_pairs, 255, 255);
        end

        %---------------------------------------------------------------------


    %     Compressed_image_size = size(run_level_pairs);
    %     Compression_Ratio = 20480/Compressed_image_size(1,1);


    %--------%--------%--------%--------%--------%--------%--------%--------%--%
    %---------%---- End of 2D DCT, Quantization, Entropy Encoding%-------------%
    %--------%--------%--------%--------%--------%--------%--------%--------%--%



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%  After the Transformation  %%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%   Assume lossless entropy coding   %%%%%%%%%%%%%%
    %%%%%%%%   Assume lossless communication channel   %%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%     For the image restoration    %%%%%%%%%%%%%%%%
    %%%%      Multiplication with Quantization Matrix         %%%%
    %%%%%%%%%%%%    2-D IDCT Matrix Multiplication   %%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    %--------%--------%--------%--------%--------%--------%--------%--------%--%
    %--------- START of Entropy Decoding, Dequantization, 2D IDCT -------------%
    %--------%--------%--------%--------%--------%--------%--------%--------%--%





        %---------------------- Run Level Decoding ---------------------------

        % construct  ZigZaged_Single_Column_Image from Run Level Pair 

        c=[];
        for i=1:2:size(run_level_pairs) % loop through run_level_pairs
            % Case 1 & Cae 2 
            % concatenate zeros according to 'run' value
            if run_level_pairs(i)<255 % only end of block should have 255 value
                zero_count=0;
                zero_count=run_level_pairs(i);
                for l=1:zero_count    % concatenation of zeros accouring to zero_count
                    c=cat(1,c,0);   % single zero concatenation
                end
                c=cat(1,c,run_level_pairs(i+1)); % concatenate single'level' i.e., a non zero value

            % Case 3: End of Block decoding
            else
                number_of_trailing_zeros= 64-mod(size(c),64);
                for l= 1:number_of_trailing_zeros    % concatenate as much zeros as needed to fill a block
                    c=cat(1,c,0); 
                end
            end
        end
        %---------------------------------------------------------------------


        %-----  prepare the ZigZaged_Single_Column_Image vector --------------
        ZigZaged_Single_Column_Image = zeros(64,4096);
        for i=1:4096
            for j=1:64
                ZigZaged_Single_Column_Image(j,i)=c(64*(i-1)+j);
            end
        end


        % Finding the reverse zigzag order (8x8 matrix)
        reverse_zigzag_order_8x8 = zeros(8,8);
        for k = 1:(size(ZigZag_Order,1) *size(ZigZag_Order,2)) 
            reverse_zigzag_order_8x8(k) = find(ZigZag_Order== k); 
        end

        %---------------------------------------------------------------------


        %--------------------------- reverse zigzag --------------------------
        %reverse zigzag procedure using the matrix indexing capability of MatLab (specially the ':' operator)
        Single_column_quantized_image = ZigZaged_Single_Column_Image(reverse_zigzag_order_8x8,:);
        %---------------------------------------------------------------------


        %image matrix construction from image column
        Image_tran_2 = col2im(Single_column_quantized_image,   [8 8],   [m n],   'distinct');


        %  Allocate the array for Image restore
        Image_restore = zeros(256,256);

        for i=1:m/8
            for j=1:n/8
                Block_temp = Image_tran_2((8*i-7):8*i,(8*j-7):8*j);
                Block_rq = Q.*Block_temp;
                Block_IDCT = T'*Block_rq*T;
                Image_restore((8*i-7):8*i,(8*j-7):8*j) = Block_IDCT;
            end
        end   

        for i=1:m
            for j=1:n
                if Image_restore(i,j) > 255
                   Image_restore(i,j) = 255;
                end

                if Image_restore(i,j) < 0
                   Image_restore(i,j) = 0;
                end

            end
        end   


    %------------------------Generate the output Image--------------------------
    output_file_name = sprintf('image_out_%d.tif',image_number);
    imwrite(uint8(Image_restore),output_file_name,'tif');
    %---------------------------------------------------------------------------



    %-------------------------Calculate the PSNR--------------------------------
    MSE = 0;

    for row = 1:m
      for col = 1:n
        MSE = MSE + (input_image_512x512(row, col) - Image_restore(row, col)) ^ 2;
      end
    end

    MSE = MSE / (m * n);
    PSNR = 10 * log10 ((255^2) / MSE);
    %---------------------------------------------------------------------------
 %{
    subplot(1,1,1)
     imshow(Image_restore./255);
     title ( sprintf('Restored image \n PSNR : %d',PSNR) )
%}
   subplot(4,2,image_number)
     imshow(Image_restore./255);
     title ( sprintf('Restored image \n PSNR : %d',PSNR) )
        
end