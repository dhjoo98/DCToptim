module TPmem_2
#( parameter BW = 12 )

(  input [8*BW-1:0]  i_data,
   input	   i_enable,
   input 	   i_clk,
   input	   i_Reset,
   output reg [8*BW-1:0] o_data,
   output reg	   o_en
);

reg [4-1:0]  counter ;
reg [8*BW-1:0] array [6-1:0]; // number of array is reduced
reg [8*BW-1:0] data_out;

wire [6*BW-1:0] col [7-1:0];  // column length is reduced, number of column is reduced as well
wire [3-1:0] index = counter[3-1:0] ;

wire [8*BW-1:0] w_data;
wire	      w_en;

//keep waveform the same
always@(posedge i_clk) begin
    if(~i_Reset) begin
    counter <= 4'b0;
    o_data <= {BW{8'b0}};
    o_en <= 1'b0;
    end
    else    begin
	o_data <= w_data ;
	o_en <= w_en ;
        if(i_enable)
        counter <= counter + 4'b1;
        else begin
          if(counter[3]==1'b1)
	          counter <= counter + 4'b1;
    	    else
    	      counter <= counter ;
    	  end
    end
end

always@(posedge i_clk) begin
    if(~i_Reset) begin
	//array[7] <= {BW{8'b0}};   //// fix array init
	//array[6] <= {BW{8'b0}};
	array[5] <= {BW{8'b0}};
	array[4] <= {BW{8'b0}};
	array[3] <= {BW{8'b0}};
	array[2] <= {BW{8'b0}};
	array[1] <= {BW{8'b0}};
	array[0] <= {BW{8'b0}};
    end
    else    begin
	if((i_enable) && (counter<=4'd5)) begin  //// fix array inputing
	array[index] <= i_data ;
	end
    end
end

//fix col allocation
assign col[0] = {{array[0][8*BW-1:7*BW]},{array[1][8*BW-1:7*BW]},{array[2][8*BW-1:7*BW]},{array[3][8*BW-1:7*BW]},{array[4][8*BW-1:7*BW]},{array[5][8*BW-1:7*BW]}};//,{array[6][8*BW-1:7*BW]}};//,{array[7][8*BW-1:7*BW]}} ;
assign col[1] = {{array[0][7*BW-1:6*BW]},{array[1][7*BW-1:6*BW]},{array[2][7*BW-1:6*BW]},{array[3][7*BW-1:6*BW]},{array[4][7*BW-1:6*BW]},{array[5][7*BW-1:6*BW]}};//,{array[6][7*BW-1:6*BW]}};//,{array[7][7*BW-1:6*BW]}} ;
assign col[2] = {{array[0][6*BW-1:5*BW]},{array[1][6*BW-1:5*BW]},{array[2][6*BW-1:5*BW]},{array[3][6*BW-1:5*BW]},{array[4][6*BW-1:5*BW]},{array[5][6*BW-1:5*BW]}};//,{array[6][6*BW-1:5*BW]}};//,{array[7][6*BW-1:5*BW]}} ;
assign col[3] = {{array[0][5*BW-1:4*BW]},{array[1][5*BW-1:4*BW]},{array[2][5*BW-1:4*BW]},{array[3][5*BW-1:4*BW]},{array[4][5*BW-1:4*BW]},{array[5][5*BW-1:4*BW]}};//,{array[6][5*BW-1:4*BW]}};//,{array[7][5*BW-1:4*BW]}} ;
assign col[4] = {{array[0][4*BW-1:3*BW]},{array[1][4*BW-1:3*BW]},{array[2][4*BW-1:3*BW]},{array[3][4*BW-1:3*BW]},{array[4][4*BW-1:3*BW]},{array[5][4*BW-1:3*BW]}};//,{array[6][4*BW-1:3*BW]}};//,{array[7][4*BW-1:3*BW]}} ;
assign col[5] = {{array[0][3*BW-1:2*BW]},{array[1][3*BW-1:2*BW]},{array[2][3*BW-1:2*BW]},{array[3][3*BW-1:2*BW]},{array[4][3*BW-1:2*BW]},{array[5][3*BW-1:2*BW]}};//,{array[6][3*BW-1:2*BW]}};//,{array[7][3*BW-1:2*BW]}} ;
//assign col[6] = {{array[0][2*BW-1:1*BW]},{array[1][2*BW-1:1*BW]},{array[2][2*BW-1:1*BW]},{array[3][2*BW-1:1*BW]},{array[4][2*BW-1:1*BW]},{array[5][2*BW-1:1*BW]},{array[6][2*BW-1:1*BW]}};//,{array[7][2*BW-1:1*BW]}} ;
//assign col[7] = {{array[0][1*BW-1:0*BW]},{array[1][1*BW-1:0*BW]},{array[2][1*BW-1:0*BW]},{array[3][1*BW-1:0*BW]},{array[4][1*BW-1:0*BW]},{array[5][1*BW-1:0*BW]},{array[6][1*BW-1:0*BW]},{array[7][1*BW-1:0*BW]}} ;

wire [2:0] zerotoseven;
assign zerotoseven = counter[2:0];
wire write_signal;
assign write_signal = counter[3];

always@(*) begin
    if((zerotoseven<=4'd5)&&(write_signal==1'b1)) begin   //fix output timing
    data_out = {col[index], 24'b0} ; //2*BW   // fix zero padding
    end
    else    begin
    data_out = 96'b0; //// fix number of zeros
    end
end

assign w_en = counter[3] ;
assign w_data = data_out ;

endmodule
