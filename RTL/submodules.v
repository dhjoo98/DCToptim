
module counter1(count,clk,reset);

  input clk,reset;
  output reg [15:0]count;

  always @(posedge clk)
  begin
    if(~reset)
      count <= 16'b0;//b1111_1111_1111_1111;
    else
      count <= count + 1'b1;
  end
endmodule

module counter2(count,clk,reset);

  input clk,reset;
  output reg [4:0]count;

  always @(posedge clk)
  begin
    if(~reset)
      begin count <= 5'b11111; end
    else if (count == 5'd30)
      begin count <= count; end // just stop here
    else
      begin count <= count + 1'b1; end
  end
endmodule
