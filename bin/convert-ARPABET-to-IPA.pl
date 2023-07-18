#!/usr/bin/env perl -w

# developed by Kow Kuroda
# created on 2022/08/25
# modifications:
# 2022/08/29: accepts syllable count at the third field
# 2023/02/07: case switch was added to deal with the BEEP data


# modules
use strict ;
use warnings ;
use utf8 ;
use Getopt::Long ;
use List::Util qw(all) ;

# variables
my $field_sep   = ',' ;
my $arpabet_sep = ' ' ;
my $joint       = "," ;

# handle options
my %args = ( debug => 0, verbose => 0, casesensitive => 0 ) ;
GetOptions(\%args,
   "help|h",           #print help
   "debug|d",          #runs in debug mode
   "verbose|v",         #runs in verbose mode
   "casesensitive|c"   #case sensitivity
) ;
print_help() if $args{help} ;

if ( $args{debug} ) { $args{verbose} = 1 ; }
#

my $map_file = shift;    # map file comes first
unless ( $map_file ) {
   die "Usage: $0 file";
}

if ( $args{verbose} ) {
   print "# map_file: $map_file\n" ;
}

## main
my %map; # before while loop
open my $fh, "<", $map_file;
while ( my $line = <$fh> ) {
   chomp $line ; # necessary!
   my ($arpabet, $ipa) = split($field_sep, $line);
   $map{$arpabet} = $ipa;
}

## checking
if ( $args{debug} ) {
   print "## mapping\n" ;
   for my $key ( keys %map ) {
      print "# $key => $map{$key}\n" ;
   }
}

# main
while ( <> ) {
   next if ( /^#+.*$/ || /^\s*$/ );
   my $line = $_;
   chomp($line);
   if ( $args{debug} ) {
      print "# $line\n";
   }
   # parse lines for fields
   my ($word, $arpabet_seq, $nsyl) = split($field_sep, $line);
   # to deal with BEEP data
   $word = lc($word) unless ( $args{casesensitive} ) ;
   $arpabet_seq = uc($arpabet_seq) unless ( $args{casesensitive} ) ;
   if ( $args{debug} ) {
      print "# $word $joint $arpabet_seq $nsyl\n";
   }
   # build fields
   my @arpabet = split($arpabet_sep, $arpabet_seq);
   if ( $args{debug} ) {
      foreach my $arpabet ( @arpabet ) {
         print "#arpabet: $arpabet\n";
      }
   }
   # conversion
   my @ipa;
   for (my $i = 0; $i < @arpabet; $i++ ) {
      $ipa[$i] = $map{$arpabet[$i]} ;
   }
   # print result
   if ( all { defined } @ipa ) {
      if ( $args{verbose} ) {
         print $word, $joint, $arpabet_seq, $joint, $nsyl, $joint, join("", @ipa), "\n";
      } else {
         print $word, $joint, join("", @ipa), "\n";
      }
   }
}


### end of script
