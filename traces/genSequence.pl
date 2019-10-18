#!/usr/bin/perl -w
#
# This script creates a series of traces following the patterns provided by
# an input address map, and a sequence file that contains a series of sequences
#
# The address map is specified using single characters for the various
# structures of the DRAM, see %mapKey below, or the comments in the example
# address map files
#
# The sequences are specified in descending hierarchical order (starting from
# Channel) with either a '.' for an unchanging element (assumed 0 unless
# otherwise specified with .:x [where x is the static number desired]) or a
# number specifiying the order of increase for each struct that will be
# incremented. The maximum number cycled through for each struct can either
# be left up to the address map, or specified using <order>:<max>
#
# Example: There are 4 rows and 8 columns
# Sequence is:
# C R B b r l h 
# . . . . 1 2 .
#
# The addresses will be generated by cycling through rows, then columns
# 1: row 0 col 0
# 2: row 1 col 0
# 3: row 2 col 0
# 4: row 3 col 0
# 5: row 0 col 1
# 6: row 1 col 1
# 7: row 2 col 1
# 8: row 3 col 1
# 9: row 0 col 2
# etc.

my $seqLength = 30_000;

my $mapFile = $ARGV[0];
my $seqFile = $ARGV[1];

my %mapKey = ('C' => 'chan', 'c' => 'pChan', 'R' => 'rank', 'B' => 'bankGroup', 'b' => 'bank', 'r' => 'row', 'l' => 'col', 'h' => 'cacheLine');

open(MAP,$mapFile) || die "Couldn't open address map file $mapFile: $!";

print STDERR "Parsing mapFile $mapFile\n";

my %maxValue;
my %bitPositions;

while(my $line = <MAP>) {
    if($line !~ /^#/) { # no comment at beginning of line
	my $curPos = 0;
	my ($bitLength, $fieldName);
	$line =~ s/\s+//g; #remove spaces
	$line =~ s/_+//g; #remove underscores
	$line =~ s/#.*//; #remove comments at end of line

	while($line) { # there's something left to parse
	    if($line =~ /:(\d+)$/) {
		$bitLength = $1;
		$line =~ s/:(\d+)$//;
	    } else {
		$bitLength = 1;
	    }

	    $fieldName = $mapKey{chop($line)};

	    for(my $ii=0;$ii<$bitLength;$ii++) {
		push(@{$bitPositions{$fieldName}}, $curPos);
		$curPos++;
	    }
	} # while there's something left to parse
    } # if line is not a comment
} # while(line = MAP)

close(MAP);

foreach my $key (keys(%bitPositions)) {
    my $bitCount = $#{$bitPositions{$key}}+1;
    $maxValue{$key} = 2**$bitCount;
    print "$bitCount\t$key: ";
    foreach my $val (@{$bitPositions{$key}}) {
	print "$val ";
    } print "\n";
}

my $seqCount = 0;
open(SEQ,$seqFile) || die "Couldn't open input sequence file $seqFile: $!";

while(my $line = <SEQ>) {
    if($line !~ /^#/) {
	my @grep = split(/\s+/,$line);
	my ($pat, %order, %value, %max);

	my $outFile = sprintf "${seqFile}.seq%02d",$seqCount;
	$seqCount++;
	open(OUT,">".$outFile);

	if(!$grep[0]) {
	    shift(@grep);
	}

	my @fileStructOrder = ('pChan', 'chan', 'rank', 'bankGroup', 'bank', 'row', 'col', 'cacheLine');

	foreach my $curStruct (@fileStructOrder) {
	    $pat = shift(@grep);
	    ($order{$curStruct}, $value{$curStruct}, $max{$curStruct}) = parsePattern($pat);
	    $patMaxValue{$curStruct} = $maxValue{$curStruct};
	    if($order{$curStruct} > 0 && $max{$curStruct} > 0) {
		$patMaxValue{$curStruct} = $max{$curStruct};
	    }
	    #if($curStruct eq 'bank') {
	    #print "Max bank is $maxValue{bank} $patMaxValue{'bank'} $max{bank} $order{bank} $pat\n";
	    #}
	}

	my @orderedStructs = sort {$order{$a} <=> $order{$b}} @fileStructOrder;
	my $curStruct = $orderedStructs[0];
	while($order{$curStruct} < 0) {
	    shift(@orderedStructs);
	    if($#orderedStructs < 0) {last;}
	    $curStruct = $orderedStructs[0];
	}
	print "ordered:\n";
	foreach $key (@orderedStructs) {
	    print "$key $order{$key}\n";
	}

	for(my $ii=0; $ii < $seqLength; $ii++) {
	    my $outAddr = 0;
	    my $carry = 1;

	    # first generate the current address using all structs
	    foreach $curStruct (@fileStructOrder) {
		$outAddr += shiftNumber($value{$curStruct}, $bitPositions{$curStruct});
	    }

	    # now increment the address using the ordered structs
	    foreach $curStruct (@orderedStructs) {
		if($carry) {
		    $value{$curStruct}++;
		    if($value{$curStruct} >= $patMaxValue{$curStruct}) {
			$value{$curStruct} = 0;
			$carry = 1;
		    } else {
			$carry = 0;
		    }
		} # if carry
	    } # foreach curStruct (orderedStructs)

	    printf OUT "%#011x P_MEM_RD 0\n", $outAddr;
	} # for seqLength

	close(OUT);
    } # if not a comment
} # while(line = SEQ)

close(SEQ);

sub parsePattern {
    my $pat = shift;
    my ($order, $value, $max);
    
    if($pat =~ /\.(:(\d+))?/) {
	$order = -1;
	$value = ($2) ? $2 : 0;
	$max = -1;
    } elsif($pat =~ /(\d+)(:(\d+))?/) {
	$order = $1;
	$value = 0;
	$max = ($3) ? $3 : -1;
    }
    return($order, $value, $max);
}

sub shiftNumber {
    my $inVal = shift;
    my $posRef = shift;

    my $curPos = 0;
    my $outVal = 0;

    while($inVal) {
	if($curPos > $#{$posRef}) {print STDERR "Warning, shiftNumber overflow in:$inVal out:$outVal curPos:$curPos posRef:@{$posRef}\n"; last;}
	$outVal += ($inVal & 0x1) << $posRef->[$curPos];
	$inVal >>= 1;
	$curPos++;
    }

    return $outVal;
}
