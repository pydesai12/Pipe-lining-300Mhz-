#!/usr/bin/perl

use Getopt::Long;

@smod = ();
$vcomm="";
@uname = ();
@uid = ();
$clkperiod = 5;
$cdly2 = "";
$debug = '';
$synthesis = '';
$toponly = '';
sub checkDW {
  my $rv="";
  if( -e "DW02_mult_2_stage.v") {
    $rv="DW02_mult_2_stage.v";
  }
  $rv = $rv." DW02_mult_3_stage.v" if( -e "DW02_mult_3_stage.v") ;
  $rv = $rv." DW02_mult_4_stage.v" if( -e "DW03_mult_4_stage.v") ;
  return $rv;
}
sub maketop {
  my $nsets=shift(@_);
  my $clkadj=shift(@_);
  my $clkhalf = ($clkperiod/2.0)*$clkadj;
  open(tf,">","tc.sv");
  printf tf '// This is a simple test bench for the calc problem.
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
        $display("pabc \%d \%d \%d sabc \%d \%d \%d",
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
      A=32\'d1111; B=32\'d2222; C=32\'d3333;
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
      pA=$random & 32\'h1f;
      pB=$random & 32\'h1f;
      pC=$random & 32\'h1f;
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
      if(debug) $display("pa \%d pb \%d pc \%d",pA,pB,pC);
      expected_result=calcres();
      exp.push_back(expected_result);
      if(debug) $display("A \%d B \%d rc \%d",ra,rb,rc);
      if(debug) $display("  Expecting \%d",expected_result);
    end
  endtask


  task doState(input reg debug, 
     	output reg pushA,output reg pushB,output reg pushC,
	output int A, output int B, output int C);
    begin
      pushA=0; pushB=0; pushC=0;
      A=32\'d1111; B=32\'d2222; C=32\'d3333;
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



reg debug=';
printf tf ($debug)?'1':'0';
printf tf ';


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
  cases_left=';
printf tf "$nsets;
";
printf tf '
  A=0; B=0; C=0; pushA=0; pushB=0; pushC=0;
  if(debug) begin
    $dumpfile("calc.vcd");
    $dumpvars(9,top);
  end
end


initial begin
  clk=0;
  forever begin
';
printf tf "    #$clkhalf;
";
printf tf '    clk=~clk;
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
    $display("Still expecting \%d results at the end of test",exp.size());
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
    if(pushZ === 1\'bx) begin
      $display("pushZ is an X");
      die();
    end
    if(pushZ) begin
      if(exp.size()==0) begin
        $display("You pushed when I didn\'t expect anything");
        die();
      end
      iz=Z;
      ez=exp.pop_front();
      if((iz != ez) || (iz !== ez)) begin
        $display("Output incorrect Got \%d expected \%d",iz,ez);
        die();
      end
    end

  end
end
endmodule
';
  close(tf);
}

sub makesynscript{
open(sf,">","synthesis.script") or die "\n\n\nFAILED --- Couldn't open the synthesis script for editing\n";
printf sf "set link_library {/apps/toshiba/sjsu/synopsys/tc240c/tc240c.db_NOMIN25 /apps/synopsys/CORE_SYNTH/libraries/syn/dw_foundation.sldb }
set target_library {/apps/toshiba/sjsu/synopsys/tc240c/tc240c.db_NOMIN25}\n";
my $ix;
printf sf "read_verilog calc.v\n";
printf sf "current_design calc\ncheck_design";
printf sf "
set_drive 0 clk
set_drive 0 rst
set_dont_touch_network clk\n";
printf sf "create_clock clk -name clk -period %f\n",$clkperiod*0.80;
printf sf "set_propagated_clock clk
set_clock_uncertainty 0.25 clk
set_propagated_clock clk
set_output_delay 0.5 -clock clk [all_outputs]
set all_inputs_wo_rst_clk [remove_from_collection [remove_from_collection [all_inputs] [get_port clk]] [get_port rst]]
";
printf sf 'set_driving_cell -lib_cell CND2X1 $all_inputs_wo_rst_clk
set_input_delay 0.5 -clock clk $all_inputs_wo_rst_clk
';
my $outdelay = $clkperiod-1.5;
printf sf "set_max_delay $outdelay -to [all_outputs]
";
my $indelay = $clkperiod-1.5;
printf sf "set_max_delay $indelay";
printf sf ' -from $all_inputs_wo_rst_clk
set_fix_hold [ get_clocks clk ]
compile -map_effort high
';
printf sf "create_clock clk -name clk -period %f\n",$clkperiod;
printf sf "set_propagated_clock clk
set_clock_uncertainty 0.25 clk
set_propagated_clock clk
update_timing
report -cell
report_timing -max_paths 10
write -hierarchy -format verilog -output calc_gates.v
quit
";
close(sf);


}
sub runvcs {
maketop(1000000,1.0);
$ENV{"SFLM_SERVER"}="SFLM_SERVER";
$ENV{"CDS_LIC_FILE"}='5280@innersanctum:/apps/cadence/license-current';
$ENV{"CDSLMD_LICENSE_FILE"}='5280@innersanctum:/apps/cadence/license-current';
$ENV{"LM_LICENSE_FILE"}='27000@innersanctum.engr.sjsu.edu:/apps/synopsys/license/current-license-key:27001@innersanctum.engr.sjsu.edu';
$ENV{"SNPSLMS_LICENSE_FILE"}='27000@innersanctum.engr.sjsu.edu:/apps/synopsys/license/current-license-key';
$ENV{"VCS_HOME"}='/apps/synopsys/VCSMX_NEW';
open(fss,">","fss");
print fss "#!/usr/bin/csh\n";
print fss "source /apps/synopsys/VCSMX_NEW/bin/environ.csh\n";
print fss "vcs +systemverilogext+.sv -sverilog ".checkDW()." calc.v tc.sv\n";
close(fss);
system("rm ./simv");
system("chmod +x fss");

printf f "vcs Simulation run on %s", `date`;
printf "Starting vcs simulation... Be patient\n";
system("./fss");
#system("vcs +v2k ".checkDW()." calc.v tc.v")==0 or die "\n\n\n\nFAILED --- vcs compile failed (Verilog problem)";
printf f "VCS finished\n";
system("rm simres");
system("./simv | tee simres")==0 or die "\n\n\n\n\nFAILED --- simulation failed (Logic problem)";
printf f "simv finished\n";
system("grep -i 'Completed calc simulation with honors (It worked)' simres")==0 or die "\n\n\n\nFAILED --- simulation didn't get correct results";
printf f " simulation OK\n";
system("rm simres");
system("rm synres.txt");
system("rm -rf simv csrc");
}

sub runncverilog{
maketop(1000000,1.0);
my $ncv = "ncverilog +sv +access+r ".checkDW()." calc.v tc.sv";
system("rm -rf fss simres");
open(fss,">","fss");
$ncv=$ncv." | tee simres";
printf fss "#!/usr/bin/csh\n";
printf fss "source /apps/design_environment.csh\n";
printf fss "$ncv\n";
close(fss);
system("chmod +x fss");
printf f "NCverilog\n";
printf f "NCverilog Simulation run on %s", `date`;
printf "Starting NCverilog simulation... Fast simulator, large test cases... Be patient\n";
system("./fss");
system("grep -i 'Completed calc simulation with honors (It worked)' simres")==0 or die "\n\n\n Failed --- ncverilog didn't get correct results";
printf f " simulation OK\n";
printf "  NC pre-synthesis simulation OK\n";

}

GetOptions("debug" => \$debug,
	   "synthesis" => \$synthesis,
	   "toponly" => \$toponly );
($#ARGV >= 1 ) or die "Need the cycle time, and result name as parameters";
$clkperiod = $ARGV[0];
open(f,">",$ARGV[1]) or die "Couldn't open the output file";


$vcomm_name = $vcomm;
$vcomm_name=~ s/.v// ;

printf f "Starting the run of the synthesis 200, 300 Mhz calc HW\n cycle time %s\n",$ARGV[0] or die "\n\n\n\nFAILED --- didn't write\n\n\n";
printf f "Run on %s", `date`;
printf f "%s on %s\n", $ENV{"USER"}, $ENV{"HOSTNAME"};
if ( $toponly ) {
  maketop(3000,1.0);
  die "\nonly made the top level\n";
} 
if ( ! $synthesis ) {
printf f "Running simulation cases\n";
runvcs;
runncverilog;
} else {
 printf f "Not running simulation\n";
}
makesynscript;
system("rm -f sss");
open(sss,">","sss");
printf sss "#!/usr/bin/csh\nsource /apps/design_environment.csh\n";
printf sss 'setenv PATH "/apps/synopsys/CORE_SYNTH/bin:\${PATH}"';
printf sss "\n";
printf sss "dc_shell -f synthesis.script | tee synres.txt\n";
close(sss);
system("chmod +x sss");
system("./sss")==0 or die "\n\n\n\nFAILED --- synthesis failed";
printf f "synthesis ran\n";
system("grep '(MET)' synres.txt")==0 or die "\n\n\n\nFAILED --- Didn't find timing met condition";
system("grep -i error synres.txt")!=0 or die "\n\n\n\nFAILED --- synthesis contained errors";
system("grep -i latch synres.txt")!=0 or die "\n\n\n\nFAILED --- synthesis created latches";
system("grep -i violated synres.txt")!=0 or die "\n\n\n\nFAILED --- synthesis violated timing";
$tline = `grep Total synres.txt`;
chomp($tline);
@gates = split(" ",$tline);
$size = @gates[5];
printf f "Total gates %s\n", $size;
#printf f "MEJ mess %s\n",@gates[5];
#die "\n\n\nFAILED --- Number of gates too small, check warinings\n\n" if ($size < 20000.0);
printf f "Design synthesized OK\n";
system("rm command.log");
system("rm default.svf");
print "\n\nSynthesis results are in file synres.txt\n";
$aline = `/sbin/ifconfig | grep eth | grep Bcast`;
chomp($aline);
@astuff = split(" ",$aline);
printf f "%s\n",@astuff[1];
system("rm gatesim.res");
maketop(5000,2.0);
system("rm -f fss");
open(fss,">","fss");
printf fss "#!/usr/bin/csh\nsource /apps/design_environment.csh\n";
printf fss "ncverilog +libext+.tsbvlibp +access+r +sv -y /apps/toshiba/sjsu/verilog/tc240c tc.sv calc_gates.v | tee gatesim.res\n";
close(fss);
system("chmod +x fss");
system("./fss");
system("grep -i 'Completed calc simulation with honors (It worked)' gatesim.res")==0 or die "\n\n\n Failed --- ncverilog(gates) didn't get correct results";
$md5 = `cat calc.pl | md5sum`;
chomp($md5);
printf f "NCverilog ran on the gates\n";
print "NCverilog ran on the gates\n";
printf f "%s %s %s\n", $md5 , $ENV{"USER"}, $ENV{"HOSTNAME"};
$mdx = `echo '$ENV{"USER"}' | md5sum`;
$mdy = `echo ~`;
chomp($mdy);
$mdz = `echo $mdy | md5sum`;
chomp($mdz);
printf f "<%s>\n",$mdz;
printf f "Completed %s", `date`;
close f;
print "Successful Completion of HW run\n";
printf "Run summary file is %s\n",$ARGV[2];
