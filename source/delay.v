module delay#(
    parameter WIDTH = 24, // Ĭ��24λ���ݿ��
    parameter DELAY = 6  // Ĭ����ʱ6��ʱ������
)
(
    input clk,  
     
    input [WIDTH-1:0] data,
      
    output reg [WIDTH-1:0] q
    );
     
     reg [WIDTH-1:0] data_reg [0:DELAY-1];     
         
     integer i;
     
     always @(posedge clk) begin
         for(i = DELAY-1; i > 0; i = i - 1) begin
             data_reg[i] <= data_reg[i-1];  
         end
         data_reg[0] <= data;
         
         q <= data_reg[DELAY-1];
     end     
endmodule 