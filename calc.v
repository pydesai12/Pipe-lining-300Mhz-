// This is a simple calculation design for use in EE287 homework
// This design performs a simple set of calculations on three variables
//
`timescale 1ns/10ps

module calc(clk,rst,A,B,C,pushA,stopA,pushB,stopB,pushC,stopC,Z,pushZ);
  input [31:0] A,B,C;
  input pushA,pushB,pushC;
  output stopA,stopB,stopC;
  output [31:0] Z;
  output pushZ;
  input clk,rst;
  reg [2:0] seen,seen_d,newin;
  
  reg all_in,all_in_d,all_in1,all_in2,all_in3,all_in4,all_in5,all_in6,all_in7,all_in8,all_in9;
  
  integer captA,captA_d,captB,captB_d,captC,captC_d;
  integer res,res_d;
  
  
  wire[63:0]w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11;
  
  
  
  reg _stopA,_stopB,_stopC;
  reg pushOut;
  
  
  reg[31:0] s01,s02,s03,s11,s12,s13,s14,s15,s16,s21,s22,s23,s24,s25,s26,s27,s28,s31,s32,s33,s34,s35,s36,s37,s41,s42,s43,s44,s45,s46,s51,s52,s53,s54,s61,s62,s63,s71,s72,s81,res_temp,s38;
  reg[31:0] f01,f02,f03,f11,f12,f13,f14,f15,f16,f21,f22,f23,f24,f25,f26,f27,f28,f31,f32,f33,f34,f35,f36,f37,f41,f42,f43,f44,f45,f46,f51,f52,f53,f54,f61,f62,f63,f71,f72,f38;  
  
  
  assign stopA=_stopA;
  assign stopB=_stopB;
  assign stopC=_stopC;
  assign pushZ=pushOut;
  assign Z = res;
  
  
  DW02_mult_2_stage #(32,32)dw1(s01,s01,1'b1,clk,w1); // a2
  DW02_mult_2_stage #(32,32)dw2(s02,s02,1'b1,clk,w2); //b2
  DW02_mult_2_stage #(32,32)dw3(s03,s03,1'b1,clk,w3); // c2
  
  DW02_mult_2_stage #(32,32)dw4(s11,s16,1'b1,clk,w4); // ac
  DW02_mult_2_stage #(32,32)dw5(s13,s16,1'b1,clk,w5); // bc
  DW02_mult_2_stage #(32,32)dw6(s11,s13,1'b1,clk,w6); // ab
   
  DW02_mult_2_stage #(32,32)dw7(s25,s27,1'b1,clk,w7); // a^2bc
  DW02_mult_2_stage #(32,32)dw8(s24,s22,1'b1,clk,w8); // b^3
  DW02_mult_2_stage #(32,32)dw9(s25,s21,1'b1,clk,w9); // a^3
  
  DW02_mult_2_stage #(32,32)dw10(s33,s36,1'b1,clk,w10); // a^4
  DW02_mult_2_stage #(32,32)dw11(s43,s45,1'b1,clk,w11); // a^5
    
  

  always @(posedge(clk) or posedge(rst)) begin
     if(rst) begin
       seen <=0;
       captA <=0;
       captB <=0;
       captC <=0;
       all_in <= 0;
       pushOut <= 0;
       f01<= 0;
       f02<= 0;
       f03<= 0;
       f11<= 0;
       f12<= 0;
       f13<= 0;
       f14<= 0;
       f15<= 0;
       f16<= 0;
       f21<= 0;
       f22<= 0;
       f23<= 0;
       f24<= 0;
       f25<= 0;
       f26<= 0;
       f27<= 0;
       f28<= 0;
       f31<= 0;
       f32<= 0;
       f33<= 0;
       f34<= 0;
       f35<= 0;
       f36<= 0;
       f37<= 0;
       f41<= 0;
       f42<= 0;
       f43<= 0;
       f44<= 0;
       f45<= 0;
       f46<= 0;
       f51<= 0;
       f52<= 0;
       f53<= 0;
       f54<= 0;
       f61<= 0;
       f62<= 0;
       f63<= 0;
       f71<= 0;
       f72<= 0;
       
       
       all_in1 <=0;
       all_in2 <=0;
       all_in3 <=0;
       all_in4 <=0;
       all_in5 <=0;
       all_in6 <=0;
       all_in7 <=0;
       all_in8 <=0;
       all_in9 <=0;

       
       res <= 0;
     end else begin
       seen<= #1 seen_d;
       captA <= #1 captA_d;
       captB <= #1 captB_d;
       captC <= #1 captC_d;
       
         
         /// stage
       
       f01 <=  s01; //a
       f02 <=s02; //b
       f03 <= s03; //c    
       
       /////stage
       
    
       
       /////stage
       
       f11 <= s11;  //a
       f12 <= s12;//a^2
       f13 <= s13; // b
       f14<= s14; // b^2
       f15<= s15; //c^2
       f16<=s16; //c
       
       /////////stage
       
       f21<=s21; //a
       f22<=s22; //b
       f23<=s23; //c^2
       f24<=s24; //b^2
       f25<=s25; //a^2
       f26<=s26; //ac
       f27<=s27; //bc
       f28<=s28; //ab

       //////stage
       
       f31<=s31;//a^2bc
       f32<=s32;//b^3
       f33<=s33; // a^3
       f34<=s34;//ac
       f35<=s35;//ab
       f36<=s36;//a
       f37<=s37;//c^2
       
       f38<=s38;//bc
       
       /////////stage
       
       f41<=s41;//ac+bc
       f42<=s42; //ab+b^3
       f43<=s43;//a^4
       f44<=s44;//a^2bc
       f45<=s45;//a
       f46<=s46;//c^2
       
       ///////stage
       
       f51<=s51;//(ac+bc)
       f52<=s52;//ab+b^3
       f53<=s53;//a^5
       f54<=s54; //a^bc + c^2
       
       
       ////////stage
       
       f61<=s61;//a^5 + (ac+bc)
       f62<=s62;//ab+b^3
       f63<=s63;//a^bc + c^2
       
       //////stage
       
       f71<=s71;// a^5 + (ac+bc)
       f72 <=s72;// ab+b^3 + a^bc + c^2
       
       res_d <=res_temp; //a^5+b^3+c^2+ab+ac+bc+a^2bc
       
        all_in <= #1 all_in_d;
       all_in1 <= #1 all_in;
       all_in2 <= #1 all_in1;
       all_in3 <= #1 all_in2;
       all_in4 <= #1 all_in3;
       all_in5 <= #1 all_in4;
       all_in6 <= #1 all_in5;
       all_in7 <= #1 all_in6;
       all_in8 <= #1 all_in7;
       all_in9 <= #1 all_in8;
       
       
       
       
       pushOut <= #1 all_in9;
       res <= #1 res_d;
       
       
       
   
       
       
       
       
       
     end

  end

  always @(*) begin
    captA_d = captA;
    captB_d = captB;
    captC_d = captC;
    all_in_d=0;
    newin = {pushA,pushB,pushC} & ~seen;
    seen_d = newin | seen;
    if(newin[2]) captA_d = A;
    if(newin[1]) captB_d = B;
    if(newin[0]) captC_d = C;
    if( (newin | seen)==3'b111) begin
      seen_d=0;
      all_in_d=1;
    end
    _stopA=seen[2];
    _stopB=seen[1];
    _stopC=seen[0];
  end
  
  always @(*) begin
//     res_d = captA*captA*captA*captA*captA+captB*captB*captB+
//             captC*captC+captA*captB+captA*captC+captB*captC+
//             captA*captA*captB*captC;

// stage 0
      s01=captA;     //a
      s02=captB;     //b 
      s03=captC;      //c

///////stage

      s11=f01;  //a
      s12=w1[31:0];  //a^2
      s13=f02;   // b
      s14=w2[31:0];   // b^2
      s15=w3[31:0]; //c^2 
      s16=f03; //c
      
///////stage
  
      s21=f11; //a
      s22=f13; //b
      s23=f15; //c^2
      s24=f14; //b^2
      s25=f12; //a^2
      s26=w4[31:0]; //ac
      s27=w5[31:0]; //bc
      s28=w6[31:0]; //ab
     
      
//////////stage      
    
      s31 = w7[31:0]; //a^2bc
      s32 = w8[31:0]; //b^3
      s33 = w9[31:0]; // a^3
      s34 = f26; //ac
      s35 = f28; //ab
      s36 = f21; //a
      s37 = f23;//c^2
      
      s38 = f27;//bc
      
///////////stage      
      
      s41 = f34+f38;//(ac+bc)
      s42 = f35 + f32; //ab+b^3
      s43 = w10[31:0]; //a^4
      s44 = f31; //a^2bc
      s45 = f36; //a
      s46 = f37; //c^2

//////////stage
      s51 = f41;//(ac+bc)
      s52 = f42;//ab+b^3
      s53 = w11[31:0];//a^5
      s54 = f44+f46; //a^bc + c^2
      
  /////////stage
      s61 = f51 + f53 ; //a^5 + (ac+bc)
      s62 = f52;//ab+b^3
      s63 = f54;//a^bc + c^2

//////////stage
      
      s71 = f61 ;//a^5 + (ac+bc)
      s72 = f62 +f63; // ab+b^3 + a^bc + c^2
      
/////////////stage
      s81 = f71 + f72; //a^5 + (ac+bc) +ab+b^3 + a^bc + c^2
      
      res_temp = s81;
       





  end

endmodule
