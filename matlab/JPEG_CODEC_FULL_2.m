clear all
close all
clc



 for image_number = 1:8 %%%%%%%%%% "Change this number" to test many different images.

    %---------------------------- Get the Image data Input ----------------------------------
     % Load input image (512x512 pixel), Each pixel has 8bit data (0~255)
     %input_image_512x512 = double( imread( 'image_in_%d.tif' ) );
     input_image_512x512 = double( imread( sprintf( 'image_in_%d.tif',image_number ),'tiff' ) );
     %input_image_512x512 = double( imread( sprintf( 'image_%d_noise.tif',image_number ),'tiff' ) );
    %-----------------------------------------------------------------------------------------
     
    [m,n] = size(input_image_512x512);

    m = floor(m/8)*8;
    n = floor(n/8)*8;
     
    %------------------------------------ show input image -----------------------------------
     subplot(4,4,image_number*2-1);
     imshow(input_image_512x512./255);
     title ( sprintf('Original image #%d \n size : %dx%d',image_number,m,n) );
    %-----------------------------------------------------------------------------------------    
    

    %------------------------------------generate input text file -----------------------------------
    x=1;
    for l = 1:64
        for k = 1:64   
            for i = 1:8
                for j = 1:8
                    vector_temp(1, x) = input_image_512x512((i+8*(l-1)),(j+8*(k-1)));
                    x= x+1;
                end
            end
        end
    end

    vector_1 = zeros(1,32768);
    vector_2 = zeros(1,32768);

    for i = 1:32768
        vector_1(1,i) = vector_temp(1,1+(i-1)*8)*(2^40) + vector_temp(1,2+(i-1)*8)*(2^32) + ...
                        vector_temp(1,3+(i-1)*8)*(2^24) + vector_temp(1,4+(i-1)*8)*(2^16) + ...
                        vector_temp(1,5+(i-1)*8)*(2^8) + vector_temp(1,6+(i-1)*8)*(2^0);
        vector_2(1,i) = vector_temp(1,7+(i-1)*8)*(2^8) + vector_temp(1,8+(i-1)*8)*(2^0);
    end

    input_vector = fopen(sprintf( 'image_in_%d.txt',image_number), 'w');

    for i = 1 : 32768

        fprintf(input_vector, '%X', vector_1(1,i));
        if(vector_2(1,i)<16)        fprintf(input_vector, '000%X \n',vector_2(1,i));
        elseif(vector_2(1,i)<256)   fprintf(input_vector, '00%X \n',vector_2(1,i));
        elseif(vector_2(1,i)<4096)  fprintf(input_vector, '0%X \n',vector_2(1,i));
        else                        fprintf(input_vector, '%X \n',vector_2(1,i));
        end

    end
    %------------------------------------------------------------------------------------------------------


    %-------------------------Generation of DCT Bases Vector Matrix ----------------------

    % Quantization coefficient after DCT operation (Not used for DCT)   
    
    Q=[16  11  10  16    24    40     51    61;
       12  12  14  19    26    58     60    55;
       14  13  16  24    40    57     69    56;
       14  17  22  29    51    87     80    62;
       18  22  37  56    68    109    103   77;
       24  35  55  64    81    104    113   92;
       49  64  78  87    103   121    120   101;
       72  92  95  98    112   100    103   99];
   
Q_pre=[16   11  10  16    24    40     51    61;  % (1,1) value (16) should be changed according to the truncation point
       12  12  14  19    26    58     60    55;
       14  13  16  24    40    57     69    56;
       14  17  22  29    51    87     80    62;
       18  22  37  56    68    109    103   77;
       24  35  55  64    81    104    113   92;
       49  64  78  87    103   121    120   101;
       72  92  95  98    112   100    103   99]; 

      %---------------------Quatization bit setup-----------------------------
        % The number of bits for DCT Coefficient Quantization
        % You can "adjust this number" to improve the qualities of images.
        C_quantization_bit =  9;          %Must be signed(8,7) -> number of coeff's binary bits increases                
        T = func_DCT_Coefficient_quant(C_quantization_bit);
                
        %If you want to check the coefficient value in hex format, please
        %use this and open the txt file.      
        filter_coef = fopen('./filt_coeff_T.txt','w');  
        for k = 1:8
            fprintf(filter_coef,'%x \n',T(k,1)*2^(C_quantization_bit-1));
        end
     %---------------------------------------------------------------------

     
     %--------------------------- DCT OPERATION --------------------------- 
     
      %---------------------Quatization bit setup-----------------------------
        % The number of bits for Result of 1D-DCT Quantization
        % You can "adjust this number" to improve the qualities of images.
        Result_1D_DCT_quantization_bit = 8; %used to be 10 - XXXXXXXXXXexcluding sign bit (remains to be seen)XXXXX 
        % The number of integer bits for Result of 1D-DCT
        num_int = 11; % XXXXXXdefault is (12,1) -> (: 소수점은 자르는게 맞는데)XXXXXXX
          %(1-D 결과의 범위가 ~1024 ~ 1024 이라는 거지 뭐) 
            %thus should be left shifted three times... : 뒤에서 반영되어야함! 
      %--------------------------- DCT OPERATION ----------------------------- 
     
        Image_tran = zeros(m,n);
        
        %disp(min(input_image_512x512,[],'all'));
        for i=1:m/8
            for j=1:n/8
                Block_temp = input_image_512x512((8*i-7):8*i,(8*j-7):8*j);
                
                Block_DCT_1D_temp = T*Block_temp'; %ㄹㅇ 찐으로 소숫점 계산한거 : T dot transpose(Block_temp)
                
                % Cut activation of 1-D DCT
                Block_DCT_1D_quant((8*i-7):8*i,(8*j-7):8*j) = func_DCTquant(Block_DCT_1D_temp, Result_1D_DCT_quantization_bit, num_int);   % result of 1D DCT for debugging
                %여기서 LSB 부분 커트한다. 앞쪽 시작은 MSB
                %result of 1-D produced. 
            
                %output BW for 2D seem to be fixed
                Block_DCT_2D_temp = T*Block_DCT_1D_quant((8*i-7):8*i,(8*j-7):8*j)';
                               
                Block_DCT_2D_quant((8*i-7):8*i,(8*j-7):8*j) = (Block_DCT_2D_temp); % result of 2D DCT for debugging

                %cut activation of 2-D DCT
                Block_DCT_final((8*i-7):8*i,(8*j-7):8*j) = func_DCTquant_trunc(Block_DCT_2D_quant((8*i-7):8*i,(8*j-7):8*j));
                
                Block_DCT = Block_DCT_final((8*i-7):8*i,(8*j-7):8*j);
                
                %Block_DCT_temp = T*Block_temp*T';
                %Block_DCT = func_DCTquant_trunc(Block_DCT_temp);
                
                Block_r = round(Q_pre.\Block_DCT); %eltwise left divide
                
                Image_tran((8*i-7):8*i,(8*j-7):8*j) = Block_r;
                
            end
        end
        disp(max(Block_DCT_1D_temp,[],'all'));
    %-------------------------------------------------------------------------------
    
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
        Single_column_quantized_image=im2col(Image_tran, [8 8],'distinct');

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
    Image_tran = col2im(Single_column_quantized_image,   [8 8],   [m n],   'distinct');


    %  Allocate the array for Image restore
    Image_restore = zeros(256,256);

    for i=1:m/8
        for j=1:n/8
            Block_temp = Image_tran((8*i-7):8*i,(8*j-7):8*j);
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

    output_file_name = sprintf( 'image_out_%d.tif',image_number);
    %output_file_name = sprintf( 'image_out_noise_%d.tif',image_number);
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
    PSNR(1,image_number) = 10 * log10 ((255^2) / MSE);
    %---------------------------------------------------------------------------


    %-------------------------Show the output image -----------------------------------
     subplot(4,4,image_number*2);
     imshow(Image_restore./255);
     title ( sprintf('Restored image #%d \n PSNR : %d',image_number,PSNR(image_number)) );
    %-----------------------------------------------------------------------------------

 
 end
 