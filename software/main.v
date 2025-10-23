module main(inclk,clk,seg,
				razr,
				sw);
input inclk,clk;
input sw;
output [7:0]seg;
output [7:0]razr;

wire clk_32768,din_clk,fr_clk,reg_clk;
wire pr1,pr2,pr3,pr4,pr5,pr6,pr7,pr8;
wire [3:0]CD00,CD10,CD20,CD30,CD40,CD50,CD60,CD70,CD80;
wire [3:0]CD01,CD11,CD21,CD31,CD41,CD51,CD61,CD71,CD81;
wire [3:0]DM0;
wire [8:0] prazr;

//Модуль PLL
divider mpll (.inclk0(clk),.c0(clk_32768),.s(din_clk));

//Делитель частоты
div_counter mdvc (.clk(clk_32768),.fr_clk(fr_clk),.inv_clk(reg_clk));

//Счётчики
cnt mc0 (.clk(inclk),.EN(fr_clk),.res(reg_clk),.pr(pr1),.O(CD00));
cnt mc1 (.clk(pr1),.EN(fr_clk),.res(reg_clk),.pr(pr2),.O(CD10));
cnt mc2 (.clk(pr2),.EN(fr_clk),.res(reg_clk),.pr(pr3),.O(CD20));
cnt mc3 (.clk(pr3),.EN(fr_clk),.res(reg_clk),.pr(pr4),.O(CD30));
cnt mc4 (.clk(pr4),.EN(fr_clk),.res(reg_clk),.pr(pr5),.O(CD40));
cnt mc5 (.clk(pr5),.EN(fr_clk),.res(reg_clk),.pr(pr6),.O(CD50));
cnt mc6 (.clk(pr6),.EN(fr_clk),.res(reg_clk),.pr(pr7),.O(CD60));
cnt mc7 (.clk(pr7),.EN(fr_clk),.res(reg_clk),.pr(pr8),.O(CD70));
cnt mc8 (.clk(pr8),.EN(fr_clk),.res(reg_clk),.O(CD80));

//Регистры
register mrg0 (.clk(fr_clk),.I(CD00),.O(CD01));
register mrg1 (.clk(fr_clk),.I(CD10),.O(CD11));
register mrg2 (.clk(fr_clk),.I(CD20),.O(CD21));
register mrg3 (.clk(fr_clk),.I(CD30),.O(CD31));
register mrg4 (.clk(fr_clk),.I(CD40),.O(CD41));
register mrg5 (.clk(fr_clk),.I(CD50),.O(CD51));
register mrg6 (.clk(fr_clk),.I(CD60),.O(CD61));
register mrg7 (.clk(fr_clk),.I(CD70),.O(CD71));
register mrg8 (.clk(fr_clk),.I(CD80),.O(CD81));

//Дешифраторы
decoder mdc1 (.I(DM0),.O(seg),.razr(prazr));


//Мультиплексор
main_mux mmm1 (.clk(din_clk),.I0(CD01),.I1(CD11),.I2(CD21),.I3(CD31),.I4(CD41),
               .I5(CD51),.I6(CD61),.I7(CD71),.I8(CD81),.O(DM0),.razr(prazr));
					
switcher msw (.sw(sw),.out(razr),.in(prazr));

endmodule

//Переключатель разрядов
module switcher(sw,in,out);
input sw;
input[8:0]in;
output reg[7:0]out;

always@(in)
begin
	if(sw==0) out[7:0] <= in[7:0];
	else if(sw==1) out[7:0] <= in[8:1];
end

endmodule


//Делитель частоты
module div_counter(clk,fr_clk,inv_clk);
input clk;
output fr_clk,inv_clk;
reg [8:0]R;

always@ (posedge clk)
   begin
	  R <= R+1'b1;
	end
	
assign fr_clk  = R[8];//0.5Hz
assign inv_clk = ~R[8];//0.5Hz

endmodule

//Десятичный счётчик
module cnt(clk,EN,O,pr,res); //Десятичный счётчик
 input clk,EN,res;
 output reg[3:0]O;
 output reg pr;
 
 always@(posedge res or posedge clk)
   begin
	 if(res) begin O <= 4'b0000; pr <= 1'b0; end
	 else 
	  begin
	  O <= O+1'b1;
	  if(O==4'b1001)begin pr <= 1'b1; 
	                      O <= 4'b0000; end
	  else begin pr<=1'b0; end
	  end
	 end
 endmodule

//Декодер семисегментного индикатора
module decoder(I,razr,O);//Decoder segmentov indicatora
 input[3:0]I;
 input[8:0]razr;
 output[7:0]O;
 
 reg[6:0]Op;
 wire Dp;
 
 always@(I)
  begin
   case(I)
     4'b0000: Op <= 8'b0111111;//0
     4'b0001: Op <= 8'b0000110;//1
     4'b0010: Op <= 8'b1011011;//2
     4'b0011: Op <= 8'b1001111;//3
     4'b0100: Op <= 8'b1100110;//4
     4'b0101: Op <= 8'b1101101;//5
     4'b0110: Op <= 8'b1111101;//6
     4'b0111: Op <= 8'b0000111;//7
     4'b1000: Op <= 8'b1111111;//8
     4'b1001: Op <= 8'b1101111;//9
     4'b1010: Op <= 8'b1110111;//A
     4'b1011: Op <= 8'b1111100;//B
     4'b1100: Op <= 8'b0111001;//C
     4'b1101: Op <= 8'b1011110;//D
     4'b1110: Op <= 8'b1111001;//E
     4'b1111: Op <= 8'b1110001;//F
	  
   endcase
  end
  

  assign Dp = (razr == ~9'b110111111)? 1 : 0;
  assign O[7:0] = {Dp, Op[6:0]};
  
endmodule

//Мультиплексор
module main_mux(I0,I1,I2,I3,I4,I5,I6,I7,I8,
                razr,O,clk);//Decoder razryadov indikatora
 input clk;
 input [3:0]I0,I1,I2,I3,I4,I5,I6,I7,I8;
 output reg[3:0]O;
 output reg [8:0]razr;
 reg[3:0]C;
 
 always@(posedge clk)
   begin 
	  C <= C+1'b1;
	  if(C==9) C<=0;
	end
 
 always@(C)
  begin
   case(C)
	 4'b0000: begin O <= I0; razr <= ~9'b111111110; end
	 4'b0001: begin O <= I1; razr <= ~9'b111111101; end
	 4'b0010: begin O <= I2; razr <= ~9'b111111011; end
	 4'b0011: begin O <= I3; razr <= ~9'b111110111; end
	 4'b0100: begin O <= I4; razr <= ~9'b111101111; end
	 4'b0101: begin O <= I5; razr <= ~9'b111011111; end
	 4'b0110: begin O <= I6; razr <= ~9'b110111111; end
	 4'b0111: begin O <= I7; razr <= ~9'b101111111; end
	 4'b1000: begin O <= I8; razr <= ~9'b011111111; end
	 default: begin O <= 0;  razr <= ~9'b111111111; end 
	endcase
 end
endmodule

//Регистр-защёлка
module register(clk,I,O);
input clk;
input[3:0]I;
output reg[3:0]O;

always@(negedge clk)
  begin 
    O <= I;
  end
endmodule


//Делитель входной частоты до 512Гц
module divider(
input inclk0,
output reg c0 = 0,
output s = 0);

localparam in_clock = 40_000_000;
localparam delitel = in_clock/512-1;
localparam reg_value = $clog2(delitel);

reg[(reg_value-1):0] cnt = 0;


always@(posedge inclk0)
	begin
		cnt<=cnt+1;
		if(cnt==delitel)
			begin
				cnt<=0;
				c0<=(~c0);
			end
	end

assign s = cnt[reg_value-6];

endmodule

