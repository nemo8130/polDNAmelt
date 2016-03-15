#!/usr/bin/perl

#==========================================================================================
#  Standalone version 16.04.2015
#==========================================================================================

# Local two state melting within polymers at defined window lengths
# Kinetically trapped structures are ignored
# All window sequences are internal (i.e., No terminal sequences)
# sequences may be of any length yet it would be treated as polymer (flanked by ds-DNA at both ends)
# If there is only one window sequence it is considered to be flanked by ds-DNA at both ends
# Fraying effect for any sequence is not considered (i.e., No bimolecular initiation correction) 
# Effect of a flanking AT and flanking GC is not considered (Room for improvement)
# Salt corrections are adapted for delG as a length dependent function (17 bp is the cutoff)
# Salt corrected for delS for all lengths of sequences similarly
# [Mon+] should be between 0.05 to 1.1 M (In this range delH does not require a salt correction)


#use CGI qw(:standard);

#print "Content-type:text/html\n\n";

#============Input Environment variables======
$inptype;$filename;$inpseq;$x;$y;$Temp;$Na;$K;$NH4;$Mg;$tag;$tparam;
#=============================================

#$qstr = $ENV{QUERY_STRING};

open (INP,"<poldnamelt.input") || die "poldnamelt.input not found in the current path\n";
@datinp = <INP>;
close INP;

open (OUT,">out.poldnamelt");

$qstr = '';

foreach $n (@datinp)
{
chomp $n;
$qstr .= $n.'&';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~env input from html~~~~~~~~~~~~~~~~~~~~
#$qstr="choice=dnaseq&filename=aranew.fa&dnaseq=GCGCGCGCTGCGCGCGCGC&tag=&tparam=&window=10&overlap=&Temp=37&Na=0.165&K=0&NH4=&Mg=0.01";
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$qstr =~ s/\'//g;

#print $qstr,"\n";

@qdata = split(/&/,$qstr);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Analyse QUERY STRING to extract input
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach $k (@qdata)
{
	if ($k =~ /^choice/ && (length($k) >= 7))
	{
	$inptype = substr($k,7, );
	}
	if ($k =~ /^filename/ && (length($k) >= 9))
	{
	$filename = substr($k,9, );
	}
	if ($k =~ /^dnaseq/ && (length($k) >= 7))
	{
	$inpseq = substr($k,7, );
	}
	if ($k =~ /^tparam/ && (length($k) >= 7))
	{
	$tparam = substr($k,7, );
	}
	if ($k =~ /^window/ && (length($k) >= 7))
	{
	$x = substr($k,7, );
	}
	if ($k =~ /^overlap/ && (length($k) >= 8))
	{
	$y = substr($k,8, );
	}
	if ($k =~ /^Temp/ && (length($k) >= 5))
	{
	$Temp = substr($k,5, );
	}
	if ($k =~ /^Na/ && (length($k) >= 3))
	{
	$Na = substr($k,3, );
	}
	if ($k =~ /^K/ && (length($k) >= 2))
	{
	$K = substr($k,2, );
	}
	if ($k =~ /^NH4/ && (length($k) >= 4))
	{
	$NH4 = substr($k,3, );
	}
	if ($k =~ /^Mg/ && (length($k) >= 3))
	{
	$Mg = substr($k,3, );
	}
	if ($k =~ /^tag/ && (length($k) >= 4))
	{
	$tag = substr($k,4, );
	}	
}

#print $inptype,"\n";
#print $inpseq,"\n";

#------------------------------------------------------
# choice of base pair step parameter (default : santa)
#------------------------------------------------------

chomp $tparam;

#print "<br> $tparam<br>\n";
	if ($tparam =~ /^\s*$/)
	{
	$tparam = 'santa';
	$stepparam = 'Santalucia, PNAS, 1998';
	}

	if ($tparam eq 'santa')
	{
	$stepparam = 'Santalucia, PNAS, 1998';
	}

	if ($tparam eq 'bresl')
	{
	$stepparam = 'Breslauer, PNAS, 1986';
	}

#print "CHECK : $tparam <br> $stepparam <br> \n\n";

#------------------------------------------------------
# Solution Temperature (in Degree Celcius) (default : 37)
#------------------------------------------------------

chomp $Temp;
	if ($Temp =~ /^\s*$/)
	{
	$Temp = 37;
	}

#------------------------------------------------------------------------------------------
# Salt concentration (in Mols/lit) (default : Na : 0.015, K: 0.15, NH4: 0.000, Mg : 0.01)
#------------------------------------------------------------------------------------------

chomp $Na;
	if ($Na =~ /^\s*$/)
	{
	$Na = 0.015;		# 15 mM
	}

chomp $K;
	if ($K =~ /^\s*$/)
	{
	$K = 0.15;		# 150 mM
	}

chomp $Na;
	if ($NH4 =~ /^\s*$/)
	{
	$NH4 = 0.000;
	}

chomp $Mg;
	if ($Mg =~ /^\s*$/)
	{
	$Mg = 0.01;		# 10 mM
	}

$Mon = $Na + $K + $NH4;			# [Mon+] = [Na+] + [K+] + [NH4+]

#####################################################################################################################
### del H is salt independent between 0.05 M and 1.1 M so any beyond range concentartion will be reset to this range 
#####################################################################################################################

	if ($Mon < 0.05)
	{
	$Mon = 0.05;
	print "<center><b>Since the input [Mon+] was less than 0.05 M it was reset to 0.05 M</b></center><br>\n";
	}
	elsif ($Mon > 1.1)
	{
	$Mon = 1.1;
	print "<center><b>Since the input [Mon+] was greater than 1.1 M it was reset to 1.1 M</b></center><br>\n";
	}

#####################################################################################################################

print "tparam : $tparam  Na : $Na  K : $K  NH4 : $NH4  Mg : $Mg  Mono : $Mon\n";


#-----------------------------------------------
# Input type (default : dirseq)
#-----------------------------------------------
chomp $inptype;
	if ($inptype =~ /^\s*$/)
	{
	$inptype = 'dirseq';
	}


#----------------------------------------------
#===============================================================================
print "<html>\n";
print "<!---------------------------------------------------------------------->\n\n";
print "<head>\n<title>OUTPUT</title>\n\n";
#===============================================================================
print "<!--=================hidenseek.js=================---------------------->\n";
print "<!--manage the property of the div tag identified by its id using a js-->\n";
print "<!--keep this style definition inside the head tag-->\n";
print "<!---------------------------------------------------------------------->\n\n";
print "<style type=\"text/css\">\n";
print "div {
position: static;
left: 100px;
top: 200px;
background-color: #f1f1f1;
width: 220px;
padding: 10px;
color: black;
border: none;
display: none;
}\n";
print "</style>\n";

print "<script language=\"JavaScript\">\n";
print "function setVisibility(id, visibility) {
document.getElementById(id).style.display = visibility;
}\n";
print "</script>\n";
print "<!---------------------------------------------------------------------->\n\n";
#===============================================================================
print "</head>\n";
print "<!---------------------------------------------------------------------->\n\n";
print "<body bgcolor = FFDEAD>\n";
print "<center><h2><u>Results</u></h2></center>\n";
#===============================================================================
$fopen = 0;
$comm = 0;
	if ($inptype eq 'fasta')
	{
	@data = ();
	$fopen = 1;
	chomp $filename;
#	print $filename,"\n";
		if ($filename =~ /^\s*$/)
		{
		$filename = 'sample.fasta';
		}

		unless (
		open (FID,$filename)
		)
		{
		$fopen = -1;
		}

		if ($fopen == -1)
		{
		print "You had chosen for \'choice=fasta\' as your input\n";
		print "But nor any Filename specified and neither any \'sample.fasta\' found in the current directory\n";
		print "The program will exit\n";
		exit;
		}

#	print "<br>\n";

	@raw = <FID>;
	foreach (@raw){chomp $_;}
		if ($raw[0] =~ m/^>/)
		{
#		print "$filename has a proper header : The file is in fasta format\n";
		}
		else
		{
		print "$filename is not written in fasta format: (MISSING HEADER initiating with '>')\n";
		exit;
		}
	$raw[0] =~ s/>//g;
		if ($fopen == 1)
		{
#		print "<center><font face = \"courier\" size =\"3\" color = #800517>Your sequence tag : $raw[0]</font></center>\n";
		}
	$tag = $raw[0];
	undef $raw[0];
	$inpseq = '';
	$inpseq = join('',@raw);
#	print "FROM FILE: $inpseq\n";
#	$seq1 =~ s/%0D//g;
#	$seq1 =~ s/%0A//g;
#	$seq =~ s/\s//g;
#	@arr = split (//,$seq);
#	@ucarr = map uc, @arr;
#	$seq1 = join ('',@ucarr);
#	$seq1 =~ tr/atgcn/ATGCN/ ;
#	$seq1 =~ s/N//g ;
#	$l1 = length ($inpseq);
#	print $l1,"\n";
	}
	elsif ($inptype == 'dirseq')
	{
	chomp $inpseq;
		if ($inpseq =~ /^\s*$/ || $inpseq eq 'Type+or+copy-paste%3B++%5BNo+header-line%28s%29+please%5D')
		{
		$inpseq = '';  
		print "<br><center><font face=\"Georgia\" size=\"5\" color = \"Black\">Please Enter a sequence first	(either type or copy-paste)<br><br>And then click on the run button</font></center>\n\n";
		exit;
		}
		else
		{
		$comm = 1;
		}
	}

#===============================================================================================
#===============================================================================================
#===============================================================================================
#        CHECK VALIDITY OF THE SEQUENCE 
#===============================================================================================
#===============================================================================================
#===============================================================================================


	@checkseq = split(//,$inpseq);
	$fcheck = 0;

	foreach $a (@checkseq)
	{
	chomp $a;
		if ($a ne "A" && $a ne "T" && $a ne "G" && $a ne "C" && $a ne "N" && $a ne "a" && $a ne "t" && $a ne "g" && $a ne "c" && $a ne "n" && $a ne " ")
                {
                $fcheck = 1;
                print "<center><h2><b>The sequence you entered:<br>  $inpseq<br><br>This is not a valid DNA sequence</b><br><b>It contains characters other than 'A/a', 'T/t', 'G/g', 'C/c', or 'N/n'  <br>Please Enter Properly</b></h2></center><br>\n";
                exit;
                }
	}

#print "fcheck:",$fcheck,"\n";

	if ($fcheck == 0)
	{
        print "<center><h2><b>The input sequence has passed the validity test<br></b></h2></center><br>\n";
	goto PROCEED;
	}

PROCEED:
	
#===============================================================================================
#===============================================================================================
#===============================================================================================

	$inpseq =~ s/%0D//g;
	$inpseq =~ s/%0A//g;
	$inpseq =~ s/\s//g;
	$inpseq =~ s/\W//g;			# Non-word character
	$inpseq =~ s/\d//g;			# digit character

	@arr = split (//,$inpseq);
	@ucarr = map uc, @arr;
	$seq1 = join ('',@ucarr);
#	$seq1 =~ tr/atgcn/ATGCN/ ;
	$seq1 =~ s/N//g ;
	$l1 = length($seq1);
	chomp $tag;
		if ($tag =~ /^\s*$/)
		{
		$tag = 'Not mentioned';    #'E.coli O157';
		}
	print "<center><font face = \"courier\" size =\"3\" color = #800517>Your sequence tag : $tag</font></center>\n";
	



	print "<center><font face = \"courier\" size =\"3\" color = #800517>Length of your input sequence : $l1</font></center>\n";
	print "<center><font face = \"courier\" size =\"3\" color = #800517>Your chosen Temperature : $Temp deg C</font></center>\n";
	print "<center><font face = \"courier\" size =\"3\" color = #800517>Your chosen database of base pair step parameter : $stepparam </font></center>\n";
	print "<center><font face = \"courier\" size =\"3\" color = #800517>Your chosen Monovalent Counterion Concentration : $Mon (M)</font></center>\n";
	print "<center><font face = \"courier\" size =\"3\" color = #800517>Your chosen Divalent Counterion Concentration : $Mg (M)</font></center>\n";
	
#------------------------------------------------
# Window size (default : length of the input seq)
#------------------------------------------------

	chomp $x;
		if ($x =~ /^\s*$/)
		{
		$x = 20;		# not $l1 anymore;
		}

#------------------------------------------------
# Overlap size (default : 0)
#------------------------------------------------

	chomp $y;
		if ($y =~ /^\s*$/)
		{
		$y = 0;
		}

#------------------------------------------------

	if ($x > $l1 || $y > $l1)
	{
		if ($x > $l1 && $y > $l1)
		{
		print "<br><center><font face=\"Georgia\" size=\"5\" color = \"Black\">Your chosen Window & Overlap size(s) both exceed the length of your input sequence<br><br> Please Enter Properly</font></center>\n\n";
		}
		elsif ($x > $l1)
		{
		print "<br><center><font face=\"Georgia\" size=\"5\" color = \"Black\">Your chosen Window size exceeds the length of your input sequence<br><br> Please Enter Properly</font></center>\n\n";
		}
		elsif ($y > $l1)
		{
		print "<br><center><font face=\"Georgia\" size=\"5\" color = \"Black\">Your chosen Overlap size exceeds the length of your input sequence<br><br> Please Enter Properly</font></center>\n\n";
		}
	exit;
	}
	else
	{
	print "<center><font face = \"courier\" size =\"3\" color = #800517>Window-size : $x bp  & Overlap : $y bp</font></center><br>\n";
	print "<p align=center><font face = \"courier\" size =\"2\" color = \"Black\"><b>[Press Ctrl and select any column using mouse]</b></font></p>\n";
	}
	if ($y == 0) 
	{
	$fragno = ($l1/$x);
	$intf = sprintf("%d",$fragno);
	$llf = $l1 - ($x*$intf);

		if(($fragno-$intf) == 0)
		{
#		print "So, Number of fragments created for $x bp window-size with $y bp overlap is $intf.\n\n";
		}
		else 
		{
#		print "So, Number of fragments created for $x bp window-size with $y bp overlap is $intf with the last fragment having a length of $llf ntd.\n\n";
		}

		for ($i=0;$i<$l1;$i+=$x)
		{
		$temp_str = substr($seq1,$i,$x);
		$check = length($temp_str);
		$cutoff = $x/2;
			if ($check >= $cutoff)
			{
			@fragment=(@fragment,$temp_str);
			}
		}
	}
	else
	{
	$fragno = ($l1/$y);
	$intf = sprintf("%d",$fragno);
	$intm = $intf - 1;
	$llf = $l1 - ($y*$intm);
		if(($fragno-$intf) == 0)
		{
#		print "So, Number of fragments created for $x bp window-size with $y bp overlap is $intf.\n\n";
		}
		else 
		{
		$intf=$intf;
#		print "So, Number of fragments created for $x bp window-size with $y bp overlap is $intf with the last fragment having a length of $llf ntd.\n\n";
		}
		for ($i=0;$i<$l1;$i+=$y)
		{
		$temp_str = substr($seq1,$i,$x);
		$check = length($temp_str);
		$cutoff = $x/2;
			if ($check >= $cutoff)
			{
			@fragment=(@fragment,$temp_str);
			}
		}
	}

#######################################################

#######################################################


	print OUT ">>Thermodynamic Parameters:\n\n";

#	if ($fopen == 1)
#	{
#---------------------------------------------------------------------------------
	print "<center><table bgcolor = \"ivory\" border=4 width=90%>\n";
	print "<tr>\n";
	print "<bgcolor=FFFFF0>\n";
	print "<th><font face = \"courier\">wseq_num</font></th>\n";
	print "<th><font face = \"courier\">delta H0  (Kcal/mol)</font></th>\n";
	print "<th><font face = \"courier\">delta S0  (cal/mol/K)</font></th>\n";
	print "<th><font face = \"courier\">delta G0(T)  (Kcal/mol)</font></th>\n";
	print "<th><font face = \"courier\">delta G0(37)  (Kcal/mol)</font></th>\n";
	print "<th><font face = \"courier\">Tm (stacking, [Mon+] corrected, santalucia '98) (degree C)</font></th>\n";
	print "<th><font face = \"courier\">Tm (stacking, [Mon+] & [Mg+2] corrected, owczarzy '08) (degree C)</font></th>\n";
	print "<th><font face = \"courier\">Tm (%GC-based) (degree C)</font></th>\n";
#	print "</td>\n";
	print "</tr>\n";
	printf OUT "%15s %15s %15s %15s %15s %15s %15s %15s\n",'wseq_num','delta_H0','delta_S0','delta_G0(T)','delta_G0(37)','Tm_St_Mon','Tm_St_Mon_Mg+2','Tm_%GC';
#---------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
	$Temp = $Temp + 273.15;
	$l2 = @fragment;
	$hold = '';
	@name = ();
	@steps = ();
	$intparam = 0;
	$nself = 0;   
	@printwseq = (); 
#-------------------------------------------------------------------------------- 
	@dlG=();@dlS=();@dlH=();@dlGp=();@Tmelt=();@TmeltGC=();
	@dlGs=();@dlSs=();@dlHs=();@dlGps=();@Tmelts=();@TmeltsGC=();@frcr=();  
	@wseqnum = ();                         
#--------------------------------------------------------------------------------
		for $i(0..$l2-1)
		{
		my $jfr = $i+1;
		$fr_no = 'wseq:'.$jfr;
		@wseqnum = (@wseqnum,$fr_no);
		my $reff = $fragment[$i];

##################################### %GC ######################################################
		$GCfraction = 0;
			for $c (0..length($reff)-1)
			{
				if (substr($reff,$c,1) eq 'G' || substr($reff,$c,1) eq 'C')
				{
				$GCfraction++;
				}
			}
		$GCfraction = sprintf("%8.3f",($GCfraction/length($reff)));
################################################################################################

			if ($jfr == 1 || $jfr == $l2)
			{
			my ($GCcnt) = GCcount ($reff);		# call subroutine for GC count if terminal sequences
				if ($jfr == 1)			# 5'-terminii
				{
					if (substr($reff,0,1) eq 'G' || substr($reff,0,1) eq 'C') # if G-C terminii
					{
					$intparam = 2;
					}
					else
					{
					$intparam = 1;				# if A-T terminii
					}
				}
				else				# 3'-terminii
				{
					if (substr($reff,length($reff)-1,1) eq 'G' || substr($reff,length($reff)-1,1) eq 'C') # if G-C terminii
					{
					$intparam = 2;
					}
					else
					{
					$intparam = 1;				# if A-T terminii
					}
				}

			}
			
		my ($flg,$pntr,$upl) = selfcomp ($reff);		# call subroutine to check for self-complementarity
			if ($flg == 1)
			{
			$nself++;
			}
		@name = split (//,$reff);
		$l3 = @name;
		$wseq = join('',@name);
		@printwseq = (@printwseq,$wseq);		
	
			for ($k=0;$k<$l3;$k++)
			{
			$hold = $name[$k].$name[$k+1];
			@steps = (@steps, $hold);
	                }
	
		@name = ();
	

			if ($tparam eq 'santa')
			{


#****** The Unified Nearest Neighbour Propagation Energies - Jhon Santalucia, Jr (Biochemistry, 1998)
	
			@AA =('-7.9','-22.2','-1.00');
			@AG =('-7.8','-21.0','-1.28');
			@AT =('-7.2','-20.4','-0.88');
			@AC =('-8.4','-22.4','-1.44');
			@GA =('-8.2','-22.2','-1.30');
			@GG =('-8.0','-19.9','-1.84');
			@GC =('-9.8','-24.4','-2.24');
			@TA =('-7.2','-21.3','-0.58');
			@TG =('-8.5','-22.7','-1.45');
			@CG =('-10.6','-27.2','-2.17');
			@A  =('2.3','4.1','1.03');	# initiation penalties for '0' GCcontent
			@G  =('0.1','-2.8','0.98');	# initiation penalties for '>0' GCcontent
			@SC =('0.0','-1.4','0.43');	# (0.0 for nonself complementary sequences)	# global

#*********************************************************

			}
			elsif ($tparam eq 'bresl')		# Breslauer
			{
			@AA = ('-9.1','-24.0','-1.67');
  			@AG = ('-8.6','-23.9','-1.19');
			@AT = ('-6.0','-16.9','-0.76');
			@AC = ('-5.8','-12.9','-1.80');
			@GA = ('-6.5','-17.3','-1.14');
			@GG = ('-7.8','-20.8','-1.35');
			@GC = ('-5.6','-13.5','-1.41');
			@TA = ('-11.9','-27.8','-3.28');
			@TG = ('-11.1','-26.7','-2.82');
			@CG = ('-11.0','-26.6','-2.75');
			@A  =('0.0','-8.38','2.6');	# initiation penalties for '0' GCcontent
			@G  =('0.0','-8.38','2.6');	# initiation penalties for '>0' GCcontent
			@SC =('0.0','-1.4','0.43');	# (0.0 for nonself complementary sequences)	# global
			}

		%thdp = 
			(
			"AA" => \@AA,
			"AG" => \@AG,
			"AT" => \@AT,
			"AC" => \@AC,
			"GA" => \@GA,
			"GG" => \@GG,
			"GC" => \@GC,
			"TA" => \@TA,
			"TG" => \@TG,
			"CG" => \@CG,
#			"A"  =>  \@A,
#			"T"  =>  \@A,
#			"G"  =>  \@G,
#			"C"  =>  \@G,
			"TT" =>  \@AA,
			"CT" =>  \@AG,
			"GT" =>  \@AC,
			"TC" =>  \@GA,	
			"CC" =>  \@GG,
			"CA" =>  \@TG
			);
	
		@keys =  keys %thdp;
		@params = values %thdp;
		$lk = @keys;
	
		$delH = 0; $delS = 0; $delG = 0; $delG_p = 0; $Tm = 0;		# Initialisation (non-self)
		$delHs = 0; $delSs = 0; $delGs = 0; $delG_ps = 0;$Tms = 0;	# Initialisation (self-comp)
	
			foreach(@steps)
			{
			$_ =~ s/\s+//g;
			}
		$isc = 0;
			foreach(@steps)
	                {
#-------------------------------------ADITIONAL CALCULATION-------------------------------------------------
#-------------If it is a self-complementary sequence then predict its thdp for a cruciform -----------------
#-----------------------------------------------------------------------------------------------------------
				if ($flg == 1)					# cruciform : self-complementary
				{
				$isc++;
					if ($pntr eq 'odd')			# window-size : odd i.e. even number of dntd steps ($x-1)
					{
					$median1 = ($x-1)/2;
					$median2 = (($x-1)/2)+1;
						for $k(0..$lk-1)
		                        	{
							if ($_ eq  $keys[$k])
	                	                	{
	                                                        if ($upl == 1)
        	                                                {
                	                                                if ($isc != $median1 && $isc != $median2)
                        	                                        {
                                	                                $delHs = $delHs + $params[$k]->[0];
                                        	                        $delSs = $delSs + $params[$k]->[1];
                                                	                $delG_ps = $delG_ps + $params[$k]->[2];
                                                        	        }
	                                                        }
        	                                                elsif ($upl == 3)
                	                                        {
                        	                                        if (($isc != ($median1-2)) && ($isc != ($median1-1)) && ($isc != $median1) && ($isc != $median2) && ($isc != ($median2+1)) && ($isc != ($median2+2)))
                                	                                {
                                        	                        $delHs = $delHs + $params[$k]->[0];
                                                	                $delSs = $delSs + $params[$k]->[1];
                                                         	        $delG_ps = $delG_ps + $params[$k]->[2];
                                                                	}
	                                                        }
								else
								{
#								print  "median : $_ : $isc\n";
								}
		                	                }
						}
					}
					elsif ($pntr eq 'even')			# window-size : even i.e. odd number of dntd steps ($x-1)
					{
					$median = $x/2;
						for $k(0..$lk-1)
	        	                	{
							if ($_ eq  $keys[$k])
	                        	        	{
	                                                        if ($upl == 2)
	                                                        {
        	                                                        if (($isc != ($median-1)) && ($isc != $median) && ($isc != ($median+1)))
                	                                                {
                        	                                        $delHs = $delHs + $params[$k]->[0];
                                	                                $delSs = $delSs + $params[$k]->[1];
                                        	                        $delG_ps = $delG_ps + $params[$k]->[2];
                                                	                }
                                                        	}
	                                                        elsif ($upl == 4)
        	                                                {
                	                                                if (($isc != ($median-3)) && ($isc != ($median-2)) && ($isc != ($median-1)) && ($isc != $median) && ($isc != ($median+1)) && ($isc != ($median+2)) && ($isc != ($median+3)))
                        	                                        {
                                	                                $delHs = $delHs + $params[$k]->[0];
                                        	                        $delSs = $delSs + $params[$k]->[1];
                                                	                $delG_ps = $delG_ps + $params[$k]->[2];
                                                        	        }
	                                                        }
								else
								{
#								print "median : $_ : $isc\n";
								}
							}
						}
					}
				}
# Consider all fragments as normal duplex : non-self complementary anyways
			
				for $k(0..$lk-1)
       	        	        {
					if ($_ eq  $keys[$k])
                       	        	{
					$delH = $delH + $params[$k]->[0];
					$delS = $delS + $params[$k]->[1];
					$delG_p = $delG_p + $params[$k]->[2];
               	        	        }
				}
			}
		@steps = ();
#-------------------------------------------------------------------------------------------------------------------
# Symmetry Correction : Entropic Penalty for the maintainence of the C2 symmetry for the self-complementary cruciforms
			if ($flg == 1)
			{
			$delHs = $delHs + $SC[0];
			$delSs = $delSs + $SC[1];
			$delG_ps = $delG_ps + $SC[2];
			}
#-------------------------------------------------------------------------------------------------------------------
# Unfavourable energy terms associated with the loss of translational freedom upon formation of the first Hydrogen-bonded basepair
# Applicable only for terminal sequences (Since here no sequence is terminal, therefore commented out)
#
		$delG = $delH - ($Temp*$delS/1000);
		$CT = 1;						# Total Strand concentration in (M)
		$mismatch = 0;
		$R = (1.987/1000);					# in Kcal/mol/K

#######################################################################################
# Two state Tm from uncorrected delS (and delH)
#######################################################################################

		$Tmunc = ($delH/(($delS/1000))) -273.15;	

# This $Tmunc is subjected to salt correction according to Owczarzy, biochemistry, 2008


#######################################################################################

		$phosphate = $x+1;		# For all sequences (all sequences are internal : flanked at both ends by phosphate : ($x-1)+2)

			if ($x < 17)					# Salt Correction for sequence length < 17 : length dependent
			{
			$delS = $delS + 0.368*$phosphate*log($Mon);
			$delG = $delG - 0.114*$phosphate*log($Mon);
			$delG_p = $delG_p - 0.114*$phosphate*log($Mon);
			}
			else						# Salt Correction for sequence length >= 17 : del G : length independent
			{						
			$delS = $delS + 0.368*$phosphate*log($Mon);	# More physical			
#			print "$phosphate\n";
			$delG = $delG - 0.175 * log($Mon) - 0.20 ;
			$delG_p = $delG_p - 0.175 * log($Mon) - 0.20;
			}

		$Tm = ($delH/(($delS/1000))) -273.15;			# Concentration independent two state melting (from salt corrected delS)
#		$Tm = ($delH/(($delS/1000) + $R*log($CT/4))) - 273.15;	# For non-self complementary association

#########################################################################################################

		$TmGC = 81.5 + 41*$GCfraction + (16.6*log($Mon/1.0+0.7*$Mon))/2.303 - (600/length($reff)) - $mismatch;  # Wetmur, 1991  Length-dependent salt-correction for Tm
			
#########################################################################################################

#####		$Tmo = $Tm + 12.5*log($Mon)/2.303 ;			# Length-independent salt-correction for Tm ## santalucia, 1996 biochemistry (obsolite)
		$Tmo = sprintf("%8.3f",$Tm);

#*********************************************************************
# New inclussions on salt corrections	# Owczarzy, biochemistry, 2008
#*********************************************************************

                $Tm = $Tmunc;

		$Nbp = length($reff);		# Number of base pairs in the duplex under consideration

			if ($Mon == 0.000)		# Purely Mg
			{
			$aa = 3.92*(10**(-5));
			$bb = -9.11*(10**(-6));
			$cc = 6.26*(10**(-5));
			$dd = 1.42*(10**(-5));
			$ee = -4.82*(10**(-4));
			$ff = 5.25*(10**(-4));
			$gg = 8.31*(10**(-5));
			
			$Tminv = (1/$Tm) + ($aa+$bb*log($Mg)) + ($GCfraction*($cc+($dd*log($Mg)))) + ((1/(2*($Nbp-1)))*($ee+($ff*log($Mg)))) + $gg*(log($Mg))**2;
			$Tm = 1/$Tminv;
			}
			else
			{
			$Ratio = sqrt($Mg)/$Mon;
#			print $Ratio,"\n";
				if ($Ratio < 0.22)		# Effectively no Mg
				{
				$Tminv = (1/$Tm) + (((4.29*$GCfraction)-3.95)*(10**(-5))*log($Mon)) + (9.4*(10**(-6))*(log($Mon))**2);		# Purely monovalent
				$Tm = 1/$Tminv;
				}
				else
				{
					if ($Ratio < 6.0)	# Both Mg and Monovalent
					{
					$bb = -9.11*(10**(-6));
					$cc = 6.26*(10**(-5));
					$ee = -4.82*(10**(-4));
					$ff = 5.25*(10**(-4));

					# Allow aa,dd,gg to vary with [Mon+]
					
					$aa = 3.92 * (10**(-5)) * (0.843 - (0.352*sqrt($Mon)) * log($Mon));
					$dd = 1.42 * (10**(-5)) * (1.297 - (4.03*(10**(-3))*log($Mon)) - (8.03*(10**(-3))*(log($Mon))**2));
					$gg = 8.31 * (10**(-5)) * (0.486 - (0.258*log($Mon)) + (5.25*(10**(-3))*(log($Mon))**3));

					$Tminv = (1/$Tm) + ($aa+$bb*log($Mg)) + ($GCfraction*($cc+($dd*log($Mg)))) + ((1/(2*($Nbp-1)))*($ee+($ff*log($Mg)))) + $gg*(log($Mg))**2;
					$Tm = 1/$Tminv;
					}
					else			# Purely Mg
					{
					$aa = 3.92*(10**(-5));
					$bb = -9.11*(10**(-6));
					$cc = 6.26*(10**(-5));
					$dd = 1.42*(10**(-5));
					$ee = -4.82*(10**(-4));
					$ff = 5.25*(10**(-4));
					$gg = 8.31*(10**(-5));
			
					$Tminv = (1/$Tm) + ($aa+$bb*log($Mg)) + ($GCfraction*($cc+($dd*log($Mg)))) + ((1/(2*($Nbp-1)))*($ee+($ff*log($Mg)))) + $gg*(log($Mg))**2;
					$Tm = 1/$Tminv;
					}
				}
			}

#		$Tm_inv = (1/$Tm) + (((4.29*$GCfraction)-3.95)*(0.00001*log($Mon))) + (9.40*0.000001*(log($Mon))**2);		#Owczarzy, 2004
#		$Tm = 1/$Tm_inv;
#########################################################################################################

		$delH = sprintf("%8.3f",$delH);	
		$delS = sprintf("%8.3f",$delS);
		$delG = sprintf("%8.3f",$delG);
		$delG_p = sprintf("%8.3f",$delG_p);
		$Tm = sprintf("%8.3f",$Tm);
		$TmGC = sprintf("%8.3f",$TmGC);

		@dlG=(@dlG,$delG);
		@dlS=(@dlS,$delS);
		@dlH=(@dlH,$delH);
		@dlGp=(@dlGp,$delG_p);
		@Tmelt=(@Tmelt,$Tm);
		@TmeltGC = (@TmeltGC,$TmGC);

		print "<tr>\n";
		print "<td width=15%><center>$fr_no</center></td>\n";
		print "<td width=20%><center>$delH</center></td>\n";
		print "<td width=20%><center>$delS</center></td>\n";
		print "<td width=20%><center>$delG</center></td>\n";
		print "<td width=20%><center>$delG_p</center></td>\n";
		print "<td width=15%><center>$Tmo</center></td>\n";
		print "<td width=15%><center>$Tm</center></td>\n";
		print "<td width=15%><center>$TmGC</center></td>\n";
		print "</tr>\n";

		printf OUT "%15s %15.3f %15.3f %15.3f %15.3f %15.3f %15.3f %15.3f\n",$fr_no,$delH,$delS,$delG,$delG_p,$Tmo,$Tm,$TmGC;


#---------------------------------CRUCIFORMS------------------------------------------------------------
			if ($flg == 1)
			{
# Correct for initiation penalties if the cruciform is situated in either terminii

				if ($intparam == 2)		# GCcontent > 0
				{
				$delHs = $delHs + $G[0];
				$delSs = $delSs + $G[1];
				$delG_ps = $delG_ps + $G[2];
				}
				elsif ($intparam == 1)		# GCcontent = 0
				{
				$delHs = $delHs + $A[0];
				$delSs = $delSs + $A[1];
				$delG_ps = $delG_ps + $A[2];
				}
			$delGs = $delHs - ($Temp*$delSs/1000);
		# Length-independent salt-correction for Tm

				if ($x < 17)					# Salt Correction for oligomer (length < 17)
				{
					if ($jfr == $l2)			# 3' terminal sequence ( 1 less phosphate)
					{
					$phosphate_s = $x-1;
#					print "terminal cruciform found\n";
					}
					else
					{
					$phosphate_s = $x;
#					print "cruciform found at frag : $jfr\n";
					}
				$delSs = $delSs + 0.368*$phosphate_s*log($Mon);
				$delGs = $delGs - 0.114*$phosphate_s*log($Mon);
				$delG_ps = $delG_ps - 0.114*$phosphate_s*log($Mon);
				}
				else						# Salt Correction for polymer
				{								
				$delGs = $delGs - 0.175 * log($Mon) - 0.20 ;
				$delG_ps = $delG_ps - 0.175 * log($Mon) - 0.20;
				}
			$Tms = ($delHs/(($delSs/1000) + $R*log($CT))) - 273.15;	# For self complementary association

###############################################################################################################

			$TmsGC = 81.5 + 41*$GCfraction + (16.6*log($Mon/(1.0+0.7*$Mon)))/2.303 - (400/length($reff)) - $mismatch;  # Wetmur, 1991  Length-dependent salt-correction for Tm
				
###############################################################################################################

			$Tms = $Tms + 12.5* log($Mon) / 2.303 ;			# Length-independent salt-correction for Tm ## santalucia, 1996 biochemistry

#			$Tms_inv = (1/$Tm) + (((4.29*$GCfraction)-3.95)*(0.00001*log($Mon))) + (9.40*0.000001*(log($Mon))**2);		#Owczarzy, 2004
#			$Tms = 1/$Tms_inv;
###############################################################################################################

#			printf SLC "%s\t\t\t%8.3f\t %8.3f\t    %8.3f\t\t    %8.3f\t\t%8.3f\n\n",$fr_no, $delHs, $delSs, $delGs,$delG_ps, $Tms;
			$delHs = sprintf("%8.3f",$delHs);	
			$delSs = sprintf("%8.3f",$delSs);
			$delGs = sprintf("%8.3f",$delGs);
			$delG_ps = sprintf("%8.3f",$delG_ps);
			$Tms = sprintf("%8.3f",$Tms);
			$TmsGC = sprintf("%8.3f",$TmsGC);
			
			@frcr=(@frcr,$fr_no);
			@dlGs=(@dlGs,$delGs);
			@dlSs=(@dlSs,$delSs);
			@dlHs=(@dlHs,$delHs);
			@dlGps=(@dlGps,$delG_ps);
			@Tmelts=(@Tmelts,$Tms);
			@TmeltsGC = (@TmeltsGC,$TmsGC);

			}
		}
	print "</table><br>\n";
	print OUT "\n\n\n\n\n";

#====================== DRAW PLOT (PHP) ==================================

#	$hl = 55;	# restriction due to php get string constraints
#	$hl = scalar(@Tmelt);

#	for $i (0..$hl-1)
#	{
#	$Tmsend[$i] = $Tmelt[$i];
#	}

	$tmphp = join('~',@Tmelt);

#	print "<form action=\"http://www.saha.ac.in/biop/www/db/local/polDNAmelt/plotTm.php\" method=\"POST\">\n";
#	print "<input type= \"hidden\" name=\"tmphp\" value=\"$tmphp\" type=\"text\">\n";
#	print "<center><input value=\"Plot Tm\" type=\"submit\"></center><br>\n";
#	print "</form>\n";


#=========================================================================
#===============================Tm========================================
#=========================================================================
#	print  "<center><h2><font face = \"courier\" size =\"4\" color = #800517>Tm</font></center></h2>\n";
#	print  "<br>\n";
#=========================================================================
	print "<!--Call hidenseek.js for div id \'sub1\'-->\n\n";
	print "<input type=button name=type value=\'Get Tm data\' onclick=\"setVisibility(\'sub1\', \'inline\');\";><input type=button name=type value=\'Hide Tm data\' onclick=\"setVisibility(\'sub1\', \'none\');\";>\n";
	print "<div id=\"sub1\">\n";
#=========================================================================	
#=========================================================================
	print  "<center><h2><font face = \"courier\" size =\"4\" color = #800517>Tm  (stacking-based)  (deg C)</font></center></h2>\n";
	print  "<br>\n";
	print  "<table bgcolor=#ADA96E border=4 width=20%>\n";
		foreach (@Tmelt)
		{
		print  "<tr>\n";
		print  "<td width=20%><center><font size=\"3\" color=\"Black\">$_</font></center></td>\n";
		print  "</tr>\n";
		}
	print  "</table>\n<br>\n\n";
#	print  "</div>\n";
#=========================================================================
#===============================delG0_p=====================================
#=========================================================================
#	print  "<center><h2><font face = \"courier\" size =\"4\" color = #800517>delG0</font></center></h2>\n";
#	print  "<br>\n";
#=========================================================================
	print "<!--Call hidenseek.js for div id \'sub2\'-->\n\n";
	print "<input type=button name=type value=\'Get delG0 data\' onclick=\"setVisibility(\'sub2\', \'inline\');\";><input type=button name=type value=\'Hide delG0 data\' onclick=\"setVisibility(\'sub2\', \'none\');\";>\n";
	print "<div id=\"sub2\">\n";
#=========================================================================
	print  "<center><h2><font face = \"courier\" size =\"4\" color = #800517>delG0(37)  (Kcal/mol)</font></center></h2>\n";
	print  "<br>\n";
	print  "<table bgcolor=#C9BE62 border=4 width=20%>\n";
		foreach (@dlGp)
		{
		print  "<tr>\n";
		print  "<td width=20%><center><font size=\"3\" color=\"Black\">$_</font></center></td>\n";
		print  "</tr>\n";
		}
	print  "</table>\n<br>\n\n";
	print OUT ">>Window Sequences:\n\n";

#=============================wseq========================================
#=========================================================================
#=========================================================================
	print "<!--Call hidenseek.js for div id \'sub3\'-->\n\n";
	print "<input type=button name=type value=\'Show wseq\' onclick=\"setVisibility(\'sub3\', \'inline\');\"><input type=button name=type value=\'Hide wseq\' onclick=\"setVisibility(\'sub3\', \'none\');\";>\n";
	print "<div id=\"sub3\">\n";
#=========================================================================
	print  "<center><h2><font face = \"courier\" size =\"5\" color = \"Red\">Window-Sequences</font></h2></center>\n";
	print  "<br>\n";
	print  "<center><table bgcolor=#82CAFF border=4 width=150%>\n";
	print  "<tr>\n";
	print  "<th><font face = \"courier\" size =\"4\" color = #800517>wseq</font></th>\n";
	print  "<th><font face = \"courier\" size =\"4\" color = #800517>sense strand sequence (5`->3`)</font></th>\n";
	print  "<th><font face = \"courier\" size =\"4\" color = #800517>length (bp)</font></th>\n";
	print  "</tr>\n";
	$wn = 0;
		foreach (@printwseq)
		{
		print  "<tr>\n";
		print  "<td width=10%><center><font size=\"2\" color=\"maroon\">$wseqnum[$wn]</font></center></td>\n";
		print  "<td width=150%><center><font size=\"2\" color=\"red\">$_</font></center></td>\n";
		print  "<td width=10%><center><font size =\"2\" color=\"blue\">",length($_),"</center></font></td>\n";
		print  "</tr>\n";
		$wn1 = sprintf("%15s",$wseqnum[$wn]);
		$len = sprintf("%5d",length($_));
		print OUT $wn1,"  ",$_,"  ",length($_),"\n";
		$wn++;
		}
	$numw = @printwseq;
	print "</table><br>\n";
#=========================================================================
#               Global Melting Origin
#=========================================================================
#=========================================================================
		if ($numw > 1)
		{
		print "<!--Call hidenseek.js for div id \'sub5\'-->\n\n";
		print "<input type=button name=type value=\'Show Comment\' onclick=\"setVisibility(\'sub5\', \'inline\');\"><input type=button name=type value=\'Hide Comment\' onclick=\"setVisibility(\'sub5\', \'none\');\";>\n";
		print "<div id=\"sub5\">\n";
		@mTmelt = ();
		@mdlG_p = ();
		$dont = 0;
			if (length($printwseq[$numw-1]) < $x)
			{
			$upto = $numw-1;			# Ommit the last wseq
			$dont = 1;
			$ldont = length($printwseq[$numw-1]);
			}
			elsif (length($printwseq[$numw-1]) == $x)
			{
			$upto = $numw;			# Consider the last wseq
			}

			for $i (0..$upto-1)
			{
			@mTmelt = (@mTmelt,$Tmelt[$i]);
			@mdlGp = (@mdlGp,$dlGp[$i]);
			}
		@smTmelt = sort {$a <=> $b} @mTmelt;
		@smdlGp = sort {$a <=> $b} @mdlGp;
		$lori = @smTmelt;
			for $i (0..$lori-1)
			{
				if ($mTmelt[$i] == $smTmelt[0])
				{
				$wno = 'wseq:'.($i+1);
				}
			}
		print  "<center><h2><font face = \"courier\" size =\"5\" color = \"Brown\">Global Melting Origin</font></h2></center>\n";
		print  "<br>\n";
		print  "<center><table bgcolor=\"#C3FDB8\" border=4 width=25%>\n";
		print  "<tr><td><center><font face = \"courier\" size =\"4\" color = #800517>Global Melting origin identified at </font><font face = \"courier\" size =\"4\" color = #254117><b>$wno </b></font><font face = \"courier\" size =\"4\" color = #800517>(Tm = $smTmelt[0] deg C; delG0(37) = $smdlGp[$lori-1] Kcal/mol)</font></center></td></tr>\n\n";
		print OUT "\n\n\n\n";
		print  OUT ">>Global Minima:\n\n";
		print  OUT "$wno (Tm = $smTmelt[0] deg C; delG0(37) = $smdlGp[$lori-1] Kcal/mol)\n\n";
		print OUT "\n\n";

			if ($dont == 1)
			{
			print  "<tr><td><font face = \"courier\" size =\"4\" color = #800517>3`-most wseq was not considered since it was shorter ($ldont bp) than the window-size specified by the user ($x bp)</font></td></tr>\n\n";
			}
		print "</table><br>\n";
		}
#=================================================================================
#=============================Local minima(s)========================================
#=========================================================================
#=======================================================================
		if (scalar(@Tmelt) > 3)
		{
		print "<!--Call hidenseek.js for div id \'sub6\'-->\n\n";
		print "<input type=button name=type value=\'Show Local minima\' onclick=\"setVisibility(\'sub6\', \'inline\');\"><input type=button name=type value=\'Hide Local minima\' onclick=\"setVisibility(\'sub6\', \'none\');\";>\n";
		print "<div id=\"sub6\">\n";
#=========================================================================

		$ll = @Tmelt;
		$loc_min = 0;					# Tm for local minima (initialized)
		$lw = '';
		$dGlm = 0;
		@Tmlm = ();
		@dlGlm = ();
		@wseqlm = ();

		print  "<center><h2><font face = \"courier\" size =\"5\" color = \"Red\">Local minima:</font></h2></center>\n";
	        print  "<br>\n";
	        print  "<center><table bgcolor=#5EFB6E border=4 width=10%>\n";
	        print  "<tr>\n";
	        print  "<th><center><font face = \"courier\" size =\"4\" color = #800517>wseq_num</font></center></th>\n";
	        print  "<th><center><font face = \"courier\" size =\"4\" color = #800517>Tm(stacking) (deg C)</font></center></th>\n";
	        print  "<th><center><font face = \"courier\" size =\"4\" color = #800517>delG0(37) (Kcal/mol)</font></center></th>\n";
	        print  "</tr>\n";
		print OUT "\n\n>>Local Minima:\n\n";
		printf OUT "%15s  %25s  %30s\n",'wseq_num','Tm_st(deg C)','delG0(37) (Kcal/mol)';
			for $i (0..$ll-2)
			{
			$j = $i+1;
				if ($Tmelt[$j] <= $Tmelt[$i])	
				{		
					if ($i == ($ll-2) && $wseqnum[$j] ne $wno)          # last data
					{
					@Tmlm = (@Tmlm,$Tmelt[$j]);
					@dlGlm = (@dlGlm,$dlGp[$j]);
					@wseqlm = (@wseqlm,$wseqnum[$j]);
#					print $Tmelt[$j],"\n";
					}
				$lw = $wseqnum[$j];
				$loc_min = $Tmelt[$j];
				$dGlm = $dlGp[$j];
				}
				else
				{
					if ($i == 0 && $wseqnum[$i] ne $wno)               # 1st data
					{
					@Tmlm = (@Tmlm,$Tmelt[$i]);
					@dlGlm = (@dlGlm,$dlGp[$i]);
					@wseqlm = (@wseqlm,$wseqnum[$i]);
#					print $Tmelt[$i],"\n";
					}
					if ($loc_min != 0 && $lw ne $wno)
					{
					@Tmlm = (@Tmlm,$loc_min);
					@dlGlm = (@dlGlm,$dGlm);
					@wseqlm = (@wseqlm,$lw);
#					print $loc_min,"\n";
					}
				$loc_min = 0;
				$lw = '';
				$dGlm = 0;
				}
			}
			for $i (0..scalar(@Tmlm)-1)
			{
			print  "<tr>\n";
			print  "<td width=10%><center><font size=\"2\" color=\"maroon\">$wseqlm[$i]</font></center></td>\n";
		        print  "<td width=10%><center><font size=\"2\" color=\"#7F462C\">$Tmlm[$i]</font></center></td>\n";
		       	print  "<td width=10%><center><font size =\"2\" color=\"#7E2217\">$dlGlm[$i]</font></center></td>\n";
			print  "</tr>\n";
			printf OUT "%15s  %25.3f  %30.3f\n",$wseqlm[$i],$Tmlm[$i],$dlGlm[$i];
			}
		}

        print "</table><br>\n";
#=================================================================================
	print "</form>\n";		# terminate action of calling 'sdnamelt.cgi'
#=================================================================================

#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
	print "<br><br>\n";
#--------------------------------------------------------------------------
#	}	# if ($fopen == 1)
	if($fopen == -1)
	{
	print "<center><h2><b>File not found in the Path</b><br><b>Please Enter Properly</b></h2></center><br>\n";
	}
print "<br>\n";
print "</body>\n";
print "</html>\n";

exit;

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#	Subroutines
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

sub selfcomp
{
my ($inp) = @_;
my $flag = 0;
my $len = length($inp);
my $mid = $len/2;
my $imid = sprintf ("%d",$mid);
my $rmd = abs($len - ($imid*2));			# remainder
my $half1 = '';
my $half2 = '';
my $comph1 = '';
my $revh2 = '';
my $next = 0;
my $pointer = '';				# return 'even' for even & 'odd' for odd
my $strand1 = '';
my $strand2 = '';
my $unpl = 0;
	if ($rmd == 0)				# window size : EVEN
	{
	$half1 = substr($inp,0,$mid);
	$half2 = substr($inp,$mid,$mid);
	$comph1 = $half1;
	$comph1 =~ tr /ATGC/TACG/ ;
	$revh2 = reverse($half2);
		if ($len >= 16)                                                 # Consider atmost 8 unpaired bases at the loop
                {
                $strand1 = substr($comph1,0,$imid-4).substr($comph1,$imid+4,$imid-4);
                $strand2 = substr($revh2,0,$imid-4).substr($revh2,$imid+4,$imid-4);
                $unpl = 4;
                }
                else                                                            # 4 for any smaller length
                {
                $strand1 = substr($comph1,0,$imid-2).substr($comph1,$imid+2,$imid-2);
                $strand2 = substr($revh2,0,$imid-2).substr($revh2,$imid+2,$imid-2);
                $unpl = 2;
                }
	$pointer = 'even';
	}
	elsif ($rmd == 1)			# window size : ODD
	{
	$half1 = substr($inp,0,$imid);
	$next = $imid + 1;
	$half2 = substr($inp,$next,$imid);
	$comph1 = $half1;
	$comph1 =~ tr /ATGC/TACG/ ;
	$revh2 = reverse($half2);
		if ($len >= 15)                                                 # Consider atmost 7 unpaired bases at the loop 
                {
                $strand1 = substr($comph1,0,$imid-3).substr($comph1,$imid+4,$imid-3);
                $strand2 = substr($revh2,0,$imid-3).substr($revh2,$imid+4,$imid-3);
                $unpl = 3;
                }
                else                                                            # 3 for any smaller length
                {
                $strand1 = substr($comph1,0,$imid-1).substr($comph1,$imid,$imid-1);
                $strand2 = substr($revh2,0,$imid-1).substr($revh2,$imid,$imid-1);
                $unpl = 1;
                }
	$pointer = 'odd';
	}
#---------------------CHECK FOR SELF COMPLEMENTARITY--------------------------
	if ($strand1 eq $strand2)
	{
	$flag = 1;
#	print "$strand1\n$strand2\n";
	}
#-----------------------------------------------------------------------------
return ($flag,$pointer,$unpl);
}

sub GCcount
{
my ($tinp) = @_;
my @str2arr = split(//,$tinp);
my $Gcnt = 0;
my $c = '';
	foreach $c (@str2arr)
	{
		if ($c eq 'G' || $c eq 'C')
		{
		$Gcnt++;
		}
	}
#print "$tinp\n$Gcnt\n";
return ($Gcnt);
}
