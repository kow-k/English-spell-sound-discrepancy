#!/usr/bin/env perl -w
# developed by Kow Kuroda (kow.kuroda@gmail.com)
#
# This script looks for instances of ipa/spell pairs in FILE1 in
# FILE2. Typically, FILE1 is freqs-1gram-XXX.txt, and FILE2 is
# extract-1gram-XXX.txt.
# You can also state -p FILE1 -s FILE2, or -s FILE2 -p FILE1 in
# option setting.
#
# created on 2022/09/23
# modifications:
# 2023/02/17: modified code
# 2023/04/21: 1) made match more restricted
#                $line =~ /\b$paired_unit\b/ => /[,;]?$paired_unit\b/
#             2) changed regex pattern for paired_unit: ^\W*\d+[ \t]+
#             3) changed output format: pair;count;instances=case1,case2,...,caseN
# 2023/08/23: minor revisions for better matches
# 2023/09/01: changed file handling by offering -p and -s options
#
use strict ;
use warnings ;
use utf8 ;
use Data::Dumper qw /Dumper/ ;

## variables
my $id    = 0; # instance counter
my $sep0  = "[,\t]" ;
my $sep1  = "," ;
my $sep2  = ";" ;
my $joint = "/" ;
my $bond  = "~" ;

## set options
use Getopt::Long ;
my %args = (
	debug => 0, verbose => 0, show_content => 0, encoding => ':utf8',
	source_file => '', pair_file => ''
) ;
GetOptions(\%args,
	"help|h",			  # print help
	"debug|d",			  # debug option
	"show_content|x",	  # file content inspection option
	"verbose|v",		  # verbose option
	"source_file|s=s",  # select paired unit file
	"pair_file|p=s",	  # select paired unit file
	"encoding|e=s",	  # file encoding
) ;
print_help() if $args{help} ;

## handle implications
if ( $args{debug} ) { $args{verbose} = 1; }
print Dumper \%args if $args{debug} ;

## handle encoding
my $enc;
if ( $args{encoding} ) {
	$enc = ":$args{encoding}" ;
} else {
	$enc = ":utf8" ;
}
binmode STDIN, $enc ;
binmode STDOUT, $enc ;
binmode STDERR, $enc ;

##use open IO => $enc ; # doesn't work
use open IO => ":utf8" ;

## read source file that contains potential instances
my $source_file ;
if ( $args{source_file} ) {
	$source_file = $args{source_file} ;
} else {
	$source_file = pop ;
}
print "# \$source_file: $source_file\n" if $args{debug} ;
#
use File::Slurp ;
my $source_raw = read_file( $source_file, binmode => ":$enc" ) ; # requires File::Slurp
my @source = split "\n", $source_raw ; # better to be here
print Dumper \@source if $args{debug} and $args{show_contents} ;


### main
## read paired ON/NC units and process over it
my $paired_unit_file ;
if ( $args{pair_file} ) {
	$paired_unit_file = $args{pair_file} ;
} else {
	$paired_unit_file = shift ;
}
print "# \$paired_unit_file: $paired_unit_file\n" if $args{debug} ;
open my $paired_units, $paired_unit_file or die "Can't open $paired_unit_file: $!" ;
## loop over lines
while ( my $paired_unit = <$paired_units> ) {
	print "# \$paired_unit: $paired_unit\n" if $args{debug} ;
	chomp $paired_unit ;
	next if ( $paired_unit =~ /^[#%]/ ) ; # ignores comment lines
	$paired_unit =~ s/^[\s\t]*\d+[\s\t]+// ; # removes leading digits in freq-paired-units format
	next if length $paired_unit == 1 ;
	## looking for instances in source
	print "# looking for <$paired_unit>\n" ;
	my @instances = ( ) ; # initialization
	$id = 0 ; # assumes global definition
	# NOTE: Slurp precludes "while ( my $line = <$source> ) {...}"
	foreach my $line ( @source ) { # $source is deadly wrong;
		print "# \$line: $line\n" if $args{debug} ;
		chomp $line ;
		my @fields = split $sep2, $line ;
		print "# \@fields: @fields\n" if $args{debug};
		my $base = $fields[0] ;
		print "# \$base: $base\n" if $args{debug} ;
		if ( $line =~ /[,;]$paired_unit[,;]/ ) { # avoids overmatching
			$instances[$id] = $base ;
		}
		$id++;
	}
	## filter out null matches
	my @instances_filtered;
	$id = 0; # assumes global definition
	foreach my $val (@instances) {
		next if !defined $val;
		if ( length($val) > 0 ) {
			$instances_filtered[$id] = $val;
			$id++;
		}
	}
	## output
	printf "$paired_unit$sep2%s$sep2%s\n", (
			scalar @instances_filtered,
			join $sep1, sort(@instances_filtered)
	) ;
	print "\n" if $args{verbose} ;
}
##
print "# verbosed\n" if $args{verbose} ;
close $paired_units ;

### end of script
