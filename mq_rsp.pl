#!/usr/local/bin/perl
# /*********************************************************************/

# Parse the sbk ref number...
# It should look like: P-xxxx/F-x/A-x
# where P - PAI, F - FCS, A - FAL, S - S2B
# xxxx for pai : AWOR,RJCT,PDNG,BLCK,RVCO,AWTR
# x for the FCS,FAL,S2B - (E)rr - (this is BLOCK), (N)ak - (this means REJECT)


use Switch;

MAIN:
$area = "$ARGV[2]";
$input_dir	= "$ENV{'AREA_ROOT_DIR'}/input/";
$output_dir	= "$ENV{'AREA_ROOT_DIR'}/output/";
$area_name 	= uc("$ENV{'AREA_NAME'}");
$bnk="$ARGV[0]";
$line_abr = "$ARGV[1]";
$ln_name = "";

if ($line_abr eq "FAL") {
	$ln_name = "fal1_snd";
	$pr_name = "fal_mq_responses";
} elsif ($line_abr eq "S2B") {
	$ln_name = "s2b1_snd";
	$pr_name = "s2b_mq_responses";
} elsif ($line_abr eq "FCS") {
	$ln_name = "fcs1_snd";
	$pr_name = "fcs_mq_responses";
} elsif ($line_abr eq "FCI") {
	$ln_name = "fci1_snd";
	$pr_name = "fci_mq_responses";
} elsif ($line_abr eq "PAI2") {
	$ln_name = "pai2_r_snd";
	$pr_name = "pai2_mq_responses";
} elsif ($line_abr eq "PAI3") {
	$ln_name = "pai3_r_snd";
	$pr_name = "pai3_mq_responses";
} else {
    print "Wrong line. Must be FAL,S2B,FCS,FCI,PAI2,PAI3\n";
	exit  (1);
}
print "Bank - $bnk, Line- $ln_name\n";
$res = system ("ent reg ${pr_name}");
#print OUTALL "TRN,Source,Amount,DB Account,Sndr Reference,Phrase,Tag,Line 1,Line 2,Line 3,Line 4,Line 5\n";
my $snd_q="";
my $rcv_q="";
my $mq="";
my $cmdq = "idi remote:$bnk/$ln_name all: end: | grep \"MQ QUEUE MANAGER\"";
open(PRTQ,"$cmdq|") || die "1. Can not open pipe: $!\n";
while (my $line = <PRTQ>)  {
	if (trim($line) =~ "PARAMETER_LIST:"){
		my @lns = split('\/', trim($line));
		$mq=$lns[3];
		$mq =~ tr/"//d;
		print "MQ MANAGER. $mq\n";
	}
}
close (PRTQ);

my $cmdq = "idi remote:$bnk/$ln_name all: end: | grep \"MQ REPLY TO QNAME\"";
open(PRTQ,"$cmdq|") || die "2. Can not open pipe: $!\n";
while (my $line = <PRTQ>)  {
	if (trim($line) =~ "PARAMETER_LIST:"){
		my @lns = split('\/', trim($line));
		$rcv_q=$lns[3];
		$rcv_q =~ tr/"//d;
		print "Receive Q. $rcv_q\n";
	}
}
close (PRTQ);

my $cmdq = "idi remote:$bnk/$ln_name all: end: | grep \"MQ TRANSMIT QNAME\"";
open(PRTQ,"$cmdq|") || die "3. Can not open pipe: $!\n";
while (my $line = <PRTQ>)  {
	if (trim($line) =~ "PARAMETER_LIST:"){
		my @lns = split('\/', trim($line));
		$snd_q=$lns[3];
		$snd_q =~ tr/"//d;
		print "Send Q. $snd_q\n";
	}
}
close (PRTQ);


# Now kill previously spawned processes (q wait) that entia does know about...
my $cmdq = "ps -ef | grep \"${snd_q}\""; 
open(PRTQ,"$cmdq|") || die "3.1. Can not open pipe: $!\n";
while (my $line = <PRTQ>)  {
	if (trim($line) =~ ""){
		my @lns = split(/\s+/, trim($line));
		if ($lns[2]==1) {
			$res = system ("kill ${lns[1]}");
		}
	}
}
close (PRTQ); 

while () {
	#  REAL ONE my $cmdq = "q -m $mq -I $snd_q ";  with wait for 120 secs.
	my $cmdq = "q -m $mq -I $snd_q -w 120";
			
	open(PRTQ,"$cmdq|") || die "4. Can not open pipe: $!\n"; 
	my $msgtype = "MT";
	while (my $line = <PRTQ>)  {
		if (index($line, "?xml version=\"1.0\"") == -1) {
			next;
		}
		if (index($line, "<MsgType>pacs") != -1) {
			$msgtype = "MX";
		}
		if (index($line, "RFMLTransaction") != -1) {
			$msgtype = "MX";
		}
		
		$trn1="";
		if ($msgtype eq "MT") {
			if (substr($line_abr,0,3) =~ "PAI") {
				$text = $line=~ /<MsgId>\s*(.*?)\s*</;
				$trn1=$1;
				print "1. MT pai text $trn1\n";
				}
			else {
				$text = $line=~ /<TransactionUID>\s*(.*?)\s*</; 
				$trn1=$1;
				print "1. MT nopai text $trn1\n";
				}
		}
		else {  # we are dealing with iso format
			if (substr($line_abr,0,3) =~ "PAI") {
				$text = $line=~ /<RqstUid>\s*(.*?)\s*</;
				$trn1=substr($1,0,16);
				print "1. MX pai text $trn1\n";
				}
			else {
				$text = $line=~ /<UniquePaymentIdentifier>\s*(.*?)\s*</; 
				$trn1=$1;
				print "1. MX nopai text $trn1\n";
				}
		}
#		print "2. text: $line\n"; 
		$trnno = $trn1; 
		$idi_trn = $trn1;
		substr($idi_trn, 8, 0) = '/';
		$idicmd = "idi mess:${idi_trn} all: end: | grep \"SBK_REF_NUM\"";
		$filename = ${input_dir} . substr($line_abr,0,3) . "_fakeACK.xml";
		$outfilename = ${output_dir} . substr($line_abr,0,3) . "_resp_ifml.xml";
		open(IDIQ,"$idicmd|") || die "5. Can not open pipe: $!\n";
		$line = <IDIQ>;
		if (trim($line) eq '') {
			print "Not Reference number. Acking...\n";
		}
		else {
			my %dct = makedict($line);
			$ln = keys %dct;  # no elements in hash dict.
			if ($ln == 0) {
				$filename=${input_dir} . substr($line_abr,0,3) . "_fakeACK.xml" 
			}
			else {
                                my $ll = $line_abr;
                                if ($ll eq 'FCI') {
                                     $ll = "FCS";
                                }
				my $dsp = $dct{substr($ll,0,3)};
				if ($dsp eq '') {
					$dsp = "ACK";
				}
				$filename=${input_dir} . substr($line_abr,0,3) . "_fake" . ${dsp} . ".xml";
			}
		}
		close(IDIQ);
		my $data = read_file($filename);
		$data =~ s/ABCD/$trnno/g;
		print "Responding to $trnno  with $filename\n";
#		print "$data"; 
		write_file($outfilename, $data);
	# q -m TESTQMGR -o USN.DVL1.FAL1_RCV_LOCAL  -F resp_ifml.xml

		my $mq_w = "q -m ${mq} -o ${rcv_q} -F ${outfilename}";
		$res = system ("$mq_w");
		print "$trnno";
#		next;
#		if ($trnno ne "" ) {
#			last; }
	}
	close (PRTQ);
}
exit  (1);

sub makedict {
	my $sbk = $_[0];
	$sbk =~ s/.*\"(.*?)\".*/$1/;  # Extract substring between 2 quotes
	my @vals = split ('/', trim($sbk));
	my %dict; # hash variable
	foreach my $v (@vals) {
		my @part = split ('-', trim($v) );
		if ($part[0] eq "PAI") {
			$dict{$part[0]} = $part[1];
		} elsif ( $part[0] eq "F") {
			if ($part[1] eq "E") {
				$dict{'FCS'} = "ERR";
			}
			elsif ($part[1] eq "N") {
				$dict{'FCS'} = "NAK";
			} 
			else {
			  print "Unknown status $part[1] for FCS\n";
			}
		} elsif ( $part[0] eq "S") {
			if ($part[1] eq "E") {
				$dict{'S2B'} = "ERR";
			}
			elsif ($part[1] eq "N") {
				$dict{'S2B'} = "NAK";
			} 
			else {
			  print "Unknown status $part[1] for S2B\n";
			}
		} elsif ( $part[0] eq "A") {
			if ($part[1] eq "E") {
				$dict{'FAL'} = "ERR";
			}
			elsif ($part[1] eq "N") {
				$dict{'FAL'} = "NAK";
			} 
			else {
			  print "Unknown status $part[1] for FAL\n";
			}
		}
		else {
		  print "Unknown status line $part[0] \n";
		}
	}
	return %dict;
}
 
sub read_file {
    my ($filename) = @_;
 
    open my $in, '<:encoding(UTF-8)', $filename or die "Could not open '$filename' for reading $!";
    local $/ = undef;
    my $all = <$in>;
    close $in;
    return $all;
}
 
sub write_file {
    my ($filename, $content) = @_;
 
    open my $out, '>:encoding(UTF-8)', $filename or die "Could not open '$filename' for writing $!";;
    print $out $content;
    close $out;
 
    return;
}
# perl trim function - remove leading and trailing whitespace
sub trim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
