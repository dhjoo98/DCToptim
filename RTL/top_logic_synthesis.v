module top_memory_test (clk,reset);

  input clk,reset;

  // HW level planning: no wiring needed!
  wire [4:0]global_clk; //
  wire [15:0]address1; // to x64
  wire [15:0]address2; // to x96
  wire [63:0]DCT1_in; //DCT1 input
  wire [63:0]DCT1_out_, TP1_out, TP2_out, TP1_out_pre, TP2_out_pre; // DCT1 output, TP input
  reg  [63:0]DCT1_out;
  wire [63:0]DCT2_in; //DCT2 input
  wire [95:0]DCT2_out_, TP3_out, TP4_out, TP3_out_pre, TP4_out_pre;
  reg  [95:0]DCT2_out;
  wire [95:0]OUT, unused_out;

  wire en1,en3_, en3;


  wire tp1_o_en, tp2_o_en, tp3_o_en, tp4_o_en;

  //SRAM32768x64 MEM_INPUT(1'b1,64'b0,address1[14:4],address1[3:0],~reset,clk, DCT1_in );
  //SRAM32768x96 MEM_OUTPUT(1'b0,OUT,address2[14:4],address2[3:0],~reset,clk, unused_out);
  DFF_64 MEM_INPUT(1'b1,64'b0,address1[14:0],~reset,clk, DCT1_in );
  DFF_96 MEM_OUTPUT(1'b0,OUT,address2[14:0],~reset,clk, unused_out);

  //combinational DCTs
  DCT_1D    DCT1(DCT1_in, DCT1_out_);
  DCT_2D    DCT2(DCT2_in, DCT2_out_,address1[2:0]);
  always @ (posedge clk) begin //1cycle delay to DCT
    if (!reset)
      begin
        DCT1_out <= 64'b0;
        DCT2_out <= 96'b0;
      end
    else begin
        DCT1_out <= DCT1_out_;
        DCT2_out <= DCT2_out_;
    end
  end
  //TP mems
  wire not_en1, not_en3;
  assign not_en1 = (global_clk>5'd3) &&(global_clk<5'd31) && ~en1;
  assign not_en3 = (global_clk>5'd18) &&(global_clk<5'd31)&&~en3;
  assign en3 = (global_clk>4'd10) && en3_;
  TPmem_1 TP1(DCT1_out, en1,clk,reset,TP1_out_pre, tp1_o_en);
  TPmem_1 TP2(DCT1_out,not_en1,clk,reset,TP2_out_pre, tp2_o_en);
  TPmem_2 TP3(DCT2_out, en3,clk,reset,TP3_out_pre, tp3_o_en);
  TPmem_2 TP4(DCT2_out,not_en3,clk,reset,TP4_out_pre, tp4_o_en);
  assign TP1_out = tp1_o_en? TP1_out_pre : 64'bx;
  assign TP2_out = tp2_o_en? TP2_out_pre : 64'bx;
  assign TP3_out = tp3_o_en? TP3_out_pre : 64'bx;
  assign TP4_out = tp4_o_en? TP4_out_pre : 64'bx;

  reg addr2_en;

  counter1  cnt1(address1,clk,reset); //Begin Input Memory right away
  counter1  cnt2(address2,clk,addr2_en); //Begin receiving Output
  counter2  global(global_clk,clk,reset);

  always @(global_clk)
    begin
      if (!reset)
        addr2_en = 1'b0;
      else if(global_clk == 5'd20)
        addr2_en = 1'b1;
    end

  TPcontrol tp1(global_clk,address1[3:0],en1,en3_,clk,reset);

  assign DCT2_in = tp2_o_en ? TP2_out : TP1_out;
  assign OUT =  tp4_o_en ? TP4_out : TP3_out;
endmodule


// sequential
module TPcontrol(global_clk,count,en1,en3,clk,reset);
input [4:0] global_clk;
input [3:0]count;
input clk,reset;
output reg en1,en3;

  always @(posedge clk)
  begin
    if (!reset)
      begin
        en1 <=1'b0;
      end
    else if(count == 4'b0001)
      en1 <= 1'b1;
    else
      begin
        if(count[2:0] == 3'b001)
          en1 <= ~en1;
      end
  end

  always @(posedge clk)
  begin
    if (!reset)
      begin
        en3 <=1'b0;
      end
    else if((count[2:0] == 3'b011)&&(global_clk>5'b01001))
        en3<=(~en3);
  end
endmodule

module DFF_64(NWRT, DIN, ADDR, NCE, CK, DO);
  	output reg [63:0] DO;
  	input [63:0] DIN;
  	input NWRT, NCE, CK;
    input [14:0] ADDR;

    	always @ (posedge CK)
  	  begin
      	   if(!NCE)
             DO <= 64'b0;
            else
             DO <= 64'b1;
      end
endmodule

module DFF_96(NWRT, DIN, ADDR, NCE, CK, DO);
  	output reg [95:0] DO;
  	input [95:0] DIN;
  	input NWRT, NCE, CK;
    input [14:0] ADDR;

    	always @ (posedge CK)
  	  begin
      	   if(!NCE)
             DO <= 96'b0;
            else
             DO <= 96'b1;
      end
endmodule
