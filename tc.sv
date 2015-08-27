// This is a simple test bench for the calc problem.
// it uses a few system Verilog concepts, but is very simple
// it generates about 10^6 tests for logical simulation
// it generates about 3*10^3 tests for gate level simulation
`timescale 1ns/10ps

module top;
  integer exp[$];

  integer ra,rb,rc;
  logic signed [5:0] pA,pB,pC;
  integer statevar; // 0 = pending, 1=pushing
  integer cases_left;
  integer expected_result;


task checkStopFlag(input logic stopA, input logic stopB,input logic stopC);
begin      
      if( ((pA > 1) || (pB > 1) || (pC > 1)) &&
	  (((pA<0) && (stopA==0)) ||
          ((pB<0) && (stopB==0)) ||
	  ((pC<0) && (stopC==0))) ) begin
        $display("Stop flag not working correctly");
        $display("pabc \0 \0 \0 sabc \0 \0 \0",
		pA,pB,pC,stopA,stopB,stopC);
        $display("Simulation stopping, failed");
        #3 $finish;
      end
end
endtask


  task setPush(input reg debug,output int A, output int B, output int C,
	output reg pushA,output reg pushB,output reg pushC);
  begin
      pushA=0; pushB=0; pushC=0;
      A=32'd1111; B=32'd2222; C=32'd3333;
      if(pA==1) begin
	pushA=1;
        A=ra;
      end  
      if(pB==1) begin
         pushB=1;
         B=rb;
      end
      if(pC==1) begin
         pushC=1;
         C=rc;
      end
      if(pA >= 0) pA=pA-1;
      if(pB >= 0) pB=pB-1;
      if(pC >= 0) pC=pC-1;
    end
  endtask

  function int calcres;
    begin
      calcres = ra*ra*ra*ra*ra+rb*rb*rb+rc*rc+ra*rb+
	ra*rc+rb*rc+ra*ra*rb*rc;
    end
  endfunction

  function reg pushRemain;
    begin
      pushRemain= (pA>0) | (pB>0) | (pC>0);
    end
  endfunction

  task setupOne(input reg debug);
    begin
      ra=$random;
      rb=$random;
      rc=$random;
      pA=$random & 32'h1f;
      pB=$random & 32'h1f;
      pC=$random & 32'h1f;
      ra=ra%31;
      rb=rb%100;
      rc=rc%500;
      pA=(pA%3)+1;
      pB=(pB%4)+1;
      pC=(pC%2)+1;
//      this.randomize() with {
//        ra < 30 && ra > -30;
//        rb < 100 && rb > -100;
//        rc < 500 && rc > -500;
//        pA < 5 && pA>0;
//        pB < 6 && pB>0;
//        pC < 4 && pC>0;
//       };
      if(debug) $display("pa \0 pb \0 pc \0",pA,pB,pC);
      expected_result=calcres();
      exp.push_back(expected_result);
      if(debug) $display("A \0 B \0 rc \0",ra,rb,rc);
      if(debug) $display("  Expecting \0",expected_result);
    end
  endtask


  task doState(input reg debug, 
     	output reg pushA,output reg pushB,output reg pushC,
	output int A, output int B, output int C);
    begin
      pushA=0; pushB=0; pushC=0;
      A=32'd1111; B=32'd2222; C=32'd3333;
      case(statevar)
        0: begin
             if(cases_left>0) begin
               setupOne(debug);
               setPush(debug,A,B,C,pushA,pushB,pushC);
               if(pushRemain()) begin
                 statevar=1;
               end else begin
                 statevar=0;
               end
             end
           end
        1: begin
             setPush(debug,A,B,C,pushA,pushB,pushC);
             if(!pushRemain()) begin
               statevar=0;
               cases_left=cases_left-1;
             end
           end
      endcase
    end
  endtask



reg debug=0;


reg run=0;

integer A,B,C;
reg pushA,pushB,pushC;
wire stopA,stopB,stopC,pushZ;
wire [31:0] Z;
integer iz,ez;

reg clk,rst;

calc c(clk,rst,A,B,C,pushA,stopA,pushB,stopB,pushC,stopC,Z,pushZ);

task die();
begin
  $display("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
  $display("Simulation failed :-(");
  $display("\n\n\n");
  #10 $finish;
end
endtask


initial begin

  statevar=0;
  cases_left=5000;

  A=0; B=0; C=0; pushA=0; pushB=0; pushC=0;
  if(debug) begin
    $dumpfile("calc.vcd");
    $dumpvars(9,top);
  end
end


initial begin
  clk=0;
  forever begin
    #3.3;
    clk=~clk;
  end
end

initial begin
  rst=0;
  run=0;
  #1;
  rst=1;
  #105;
  rst=0;
  repeat(4) @(posedge(clk));
  run=1;
  while(cases_left > 0) @(posedge(clk));
  repeat(25) @(posedge(clk));
  if(exp.size()> 0) begin
    $display("Still expecting \0 results at the end of test",exp.size());
    die();
  end
  #200;
  $display("\n\n\nCompleted calc simulation with honors (It worked)\n\n\n");
  $finish;
end

always @(posedge(clk)) begin
  if(run) begin
    #1;
    doState(debug,pushA,pushB,pushC,A,B,C);
    #1;
    checkStopFlag(stopA,stopB,stopC);
  end
end


always @(posedge(clk)) begin
  if(run) begin
    #1;
    if(pushZ === 1'bx) begin
      $display("pushZ is an X");
      die();
    end
    if(pushZ) begin
      if(exp.size()==0) begin
        $display("You pushed when I didn't expect anything");
        die();
      end
      iz=Z;
      ez=exp.pop_front();
      if((iz != ez) || (iz !== ez)) begin
        $display("Output incorrect Got \0 expected \0",iz,ez);
        die();
      end
    end

  end
end
endmodule
