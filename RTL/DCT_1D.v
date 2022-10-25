module DCT_1D(in,out);
  input [63:0] in;
  output [63:0] out;
  //in : 8 element of 8 bits
  //out : 8 element of 8 bits

  wire [7:0] pixel [7:0]; // unsigned 0~255
  wire signed [9:0] x07, x16, x25, x34, x0_7, x1_6, x2_5, x3_4; // increase with sign bit

  assign pixel[7] = in[7:0];
  assign pixel[6] = in[15:8];
  assign pixel[5] = in[23:16];
  assign pixel[4] = in[31:24];
  assign pixel[3] = in[39:32];
  assign pixel[2] = in[47:40];
  assign pixel[1] = in[55:48];
  assign pixel[0] = in[63:56];


  assign x07 =  pixel[0] + pixel[7];
  assign x16 =  pixel[1] +  pixel[6];
  assign x25 =  pixel[2]  +  pixel[5];
  assign x34 =  pixel[3]  +  pixel[4];
  assign x0_7 =  pixel[0]  -  pixel[7];
  assign x1_6 =  pixel[1]  -  pixel[6];
  assign x2_5 =  pixel[2]  -  pixel[5];
  assign x3_4 =  pixel[3]  -  pixel[4]; //who said this was all positive

//Even DCT
  wire signed [10:0] b1, b2, b3, b4;
  assign b1 = x07 + x34;
  assign b2 = x16 + x25;
  assign b3 = x07 - x34;
  assign b4 = x16 - x25;

  //z0, z4
    wire signed [11:0] c1, c2;
    assign c1 = b1 + b2;
    assign c2 = b1 - b2;
    wire signed [17:0] shift6_c1, shift6_c2;
    wire signed [16:0] shift5_c1, shift5_c2;
    wire signed [13:0] shift2_c1, shift2_c2;
      assign shift6_c1 = {c1, 6'b0};
      assign shift5_c1 = {c1, 5'b0};
      assign shift2_c1 = {c1, 2'b0};
      assign shift6_c2 = {c2, 6'b0};
      assign shift5_c2 = {c2, 5'b0};
      assign shift2_c2 = {c2, 2'b0};

    wire signed [18:0] z0, z4;
      assign z0 = shift6_c1 + shift5_c1 - shift2_c1 - c1;
      assign z4 = shift6_c2 + shift5_c2 - shift2_c2 - c2;

  //z2
    wire signed [17:0] shift7_b3;
    wire signed [15:0] shift5_b3, shift5_b4;
    wire signed [14:0] shift4_b3, shift4_b4;
    wire signed [13:0] shift3_b3;
    wire signed [11:0] shift1_b3;
      assign shift7_b3 = {b3, 7'b0};
      assign shift5_b3 = {b3, 5'b0};
      assign shift4_b3 = {b3, 4'b0};
      assign shift3_b3 = {b3, 3'b0};
      assign shift1_b3 = {b3, 1'b0};
      assign shift5_b4 = {b4, 5'b0};
      assign shift4_b4 = {b4, 4'b0};

    wire signed [20:0] z2;
      assign z2 = shift7_b3 - shift4_b3 - shift1_b3  + shift5_b4 + shift4_b4 + b4;


    //shift sevens
      wire signed [16:0] shift7_x0_7, shift7_x1_6, shift7_x2_5;
        assign shift7_x0_7 = {x0_7, 7'b0};
        assign shift7_x1_6 = {x1_6, 7'b0};
        assign shift7_x2_5 = {x2_5, 7'b0};

    //shift sixs
      wire signed [15:0] shift6_x0_7, shift6_x1_6, shift6_x2_5, shift6_x3_4;
        assign shift6_x0_7 = {x0_7, 6'b0};
        assign shift6_x1_6 = {x1_6, 6'b0};
        assign shift6_x2_5 = {x2_5, 6'b0};
        assign shift6_x3_4 = {x3_4, 6'b0};

    //shift fives
      wire signed [14:0] shift5_x0_7, shift5_x1_6, shift5_x3_4;
        assign shift5_x0_7 = {x0_7, 5'b0};
        assign shift5_x1_6 = {x1_6, 5'b0};
        assign shift5_x3_4 = {x3_4, 5'b0};

    //shift fours
      wire signed [13:0] shift4_x1_6, shift4_x2_5, shift4_x3_4;
        assign shift4_x1_6 = {x1_6, 4'b0};
        assign shift4_x2_5 = {x2_5, 4'b0};
        assign shift4_x3_4 = {x3_4, 4'b0};

    //shift threes
      wire signed [12:0] shift3_x0_7, shift3_x1_6, shift3_x2_5, shift3_x3_4;
        assign shift3_x0_7 = {x0_7, 3'b0};
        assign shift3_x1_6 = {x1_6, 3'b0};
        assign shift3_x2_5 = {x2_5, 3'b0};
        assign shift3_x3_4 = {x3_4, 3'b0};

    //shift ones
      wire signed [10:0] shift1_x0_7, shift1_x1_6, shift1_x2_5, shift1_x3_4;
        assign shift1_x0_7 = {x0_7, 1'b0};
        assign shift1_x1_6 = {x1_6, 1'b0};
        assign shift1_x2_5 = {x2_5, 1'b0};
        assign shift1_x3_4 = {x3_4, 1'b0};


  //some sharing for odd DCT
      wire signed [19:0] sharing1, sharing2;
        assign sharing1 = shift6_x0_7 + shift3_x0_7;
        assign sharing2 = shift6_x3_4 + shift3_x3_4;

  //odd DCT
      wire signed [19:0] c1x0_7, c1x1_6, c1x2_5;
        assign c1x0_7 = shift7_x0_7 - shift1_x0_7 ;
        assign c1x1_6 = shift7_x1_6 - shift1_x1_6 ;
        assign c1x2_5 = shift7_x2_5 - shift1_x2_5 ;

      wire signed [19:0] c3x0_7, c3x1_6, c3x3_4;
         assign c3x0_7 = sharing1 + shift5_x0_7 + shift1_x0_7;
         assign c3x1_6 = shift6_x1_6 + shift5_x1_6 + shift3_x1_6 + shift1_x1_6;
         assign c3x3_4 = sharing2 + shift5_x3_4;// + shift1_x3_4;

      wire signed [19:0] c5x0_7, c5x2_5, c5x3_4;
         assign c5x0_7 = sharing1;
         assign c5x2_5 = shift6_x2_5 + shift3_x2_5 - x2_5;
         assign c5x3_4 = sharing2 - x3_4;

      wire signed [19:0] c7x1_6, c7x2_5, c7x3_4;
         assign c7x1_6 = shift4_x1_6 + shift3_x1_6 + x1_6;
         assign c7x2_5 = shift4_x2_5 + shift3_x2_5;
         assign c7x3_4 = shift4_x3_4 + shift3_x3_4 + x3_4;


  wire signed [20:0] z1, z3, z5;
     assign z1 = c1x0_7 + c3x1_6 + c5x2_5 + c7x3_4;
     assign z3 = c3x0_7 - c7x1_6 - c1x2_5 - c5x3_4;
     assign z5 = c5x0_7 - c1x1_6 + c7x2_5 + c3x3_4; //here's shift3 deletion is last resort.

  assign out={z0[18:11],z1[18:11],z2[18:11],z3[18:11],z4[18:11],z5[18:11],16'b0};//z6[18:11],z7[18:11]}; // output 72bit, 8 of 9 bits

endmodule
