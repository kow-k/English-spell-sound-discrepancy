#!/usr/bin/env perl -w
#
# developed by Kow Kuroda
# created on 2022/09/08
# This scripts extract ipa-spell units.
#
# modified on
# 2022/09/09: added use open IO => ":utf8" ;
# 2022/09/12: binmode(STDX, ":encodig") were added to handle garbled text
#             on MacBook Pro at office
# 2022/09/16: added tab-separation for input, r_as_vowel option
# 2022/09/20: added # handling
# 2022/09/22: added included h as vowel
# 2022/09/23: implemented full-fleged option handling,
#             added inverted output, improved r-handling
# 2023/02/09: implemented bigram mode, refactored the code
# 2023/02/10: implemented filtering on input to accept pairs with frequencies
# 2023/02/14: implemented trigram mode
# 2023/02/16: made h as V optional; fixed a bug in bigram, trigram modes
# 2023/04/08: modified freq_leader to accept \d+; added handling of /ɜ/
# 2023/08/10: added /y/ to Vchar clases
## declarations
use strict ;
use warnings ;
use Getopt::Long ;
use List::Util qw(all any) ;
#use feature 'unicode_strings' ;
use utf8 ;
#use open IO => ":locale" ;
use open IO => ":utf8" ; # This dispenses with the following;
## oddly, $enc doesn't work here.
my $enc = "utf8" ;
binmode STDIN,  ":$enc" ;
binmode STDOUT, ":$enc" ;
binmode STDERR, ":$enc" ;
#use Encode qw(decode_utf8) ; # Stackoverflow

## variables
# $r_as_H = 0 ; # treats [h] as a vowel
# $r_as_V = 0 ; # treats [ɹ] as a vowel
my $Vchar       = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊ]+)" ;
my $VcharPlusH  = "([həɚɜɝaɑɒæʌɛeɪiɨoɔuʊ]+)" ;
my $VcharPlusR  = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊ]+|ɹ)" ;  # picks up /ɹ/ alone successfully
my $VcharPlusHR = "([həɚɜɝaɑɒæʌɛeɪiɨoɔuʊ]+|ɹ)" ;
#
my $leader_sep = ": " ;
#my $freq_leader = "\ +\d+\ +" ; # failed to work due to offensive \d
my $freq_leader = "(^\ *[1-9][0-9]*\ +|^[0-9]+,)" ;
my $sep0  = "[,\t]" ; # handles csv and tsv files
my $vseq  = "," ;
my $fseq  = ";" ;
my $ipa_sep = "[0123#]" ;
my $spell_sep = "[/#]" ;
my $joint = ":";
my $v_bond  = "~" ;
my $void  = "#" ;
my $missing = "_";
#
my %args = ( debug => 0, verbose => 0, r_as_V => 0, h_as_V => 0 );
GetOptions(\%args,
   "help",         # print help
   "debug|d",      # runs in debug mode
   "verbose|v",    # runs in verbose mode
   "r_as_V|r",     # treats [ɹ] as a vowel
   "h_as_V|h",     # treats [h] as a vowel
   "inverted|i",   # inverts ipa-spell order in pairing
   "unstrip|u",    # retains stress-marks and slashes
   "bigram|b",     # runs in bigram mode
   "trigram|t",    # runs in bigram mode
   "extensive|e"   # bigrams extend unigrams
) ;

## handle implications
if ( $args{debug} ) { $args{verbose} = 1 ; }
#
#my $file = shift ; # selects input file
#print "#input file: $file" if $args{debug} ;
#open my $data, $file or die "Can't open $file: $!" ;

## main
my ($i, $j) = (0, 0) ;
while ( my $line = <> ) {
   print $line if $args{debug};
   chomp $line;
   next if $line =~ /^[#%]/; # ignores comment lines
   ## remove freq_leader
   $line =~ s/$freq_leader//;
   my ($leader, $pair_raw);
   if ( $line =~ /$leader_sep/ ) {
      my @seg = split $leader_sep, $line;
      $leader = $seg[0];
      $pair_raw = $seg[scalar @seg - 1];
   } else {
      $leader = undef;
      $pair_raw = $line;
   }
   ## analyze input
   my ($ipa, $slashed) = split $sep0, $pair_raw;
   print "# ipa: $ipa; slashed: $slashed\n" if $args{debug};
   #
   my ($sound, $spell);
   if ( $args{unstrip} ) {
      $sound = $ipa ;
      $spell  = $slashed ;
   }
   else {
      $sound = $ipa =~ s/$ipa_sep//gr ; # added # later
      $spell  = $slashed =~ s/$spell_sep//gr ;
   }
   ## define sound-spell pair
   my $pair ;
   if ( $args{inverted} ) { $pair = "$spell$joint$sound$fseq" ; }
   else { $pair = "$sound$joint$spell$fseq" ; }
   print $pair ;
   #
   my @ipa_segs = split /$ipa_sep/, $ipa ; # added # later
   if ( $args{debug} ) {
      print "\n" ;
      for my $i ( 0 .. @ipa_segs ) {
         print "# ipa_seg$i: $ipa_segs[$i]\n" if defined $ipa_segs[$i];
      }
   }
   #
   my @spell_segs = split $spell_sep, $slashed ; # added # later
   if ( $args{debug} ) {
      for my $i ( 0 .. @spell_segs ) {
         print "# spell_seg$i: $spell_segs[$i]\n" if defined $spell_segs[$i] ;
      }
   }
   my @ipa_segs_orig = @ipa_segs ; # stored for vowel sequence generation
   my @spell_segs_orig = @spell_segs ;
   ## define vowel sequence
   my @v_cluster ;
   for $i ( 0..scalar @spell_segs_orig ) {
      if ( $i < scalar @ipa_segs_orig ) {
         my $ipa_seg = $ipa_segs[$i] ;
         print "# ipa_seg$i: $ipa_seg\n" if $args{verbose} ;
         if ( $args{h_as_V} ) {
            if ($args{r_as_V}) {
               $ipa_seg =~ m/$VcharPlusHR\b/ ; # Crucially ...\b here.
               $v_cluster[$i] = $1 ;
            } else {
               $ipa_seg =~ m/$VcharPlusH/ ;
               $v_cluster[$i] = $1 ;
            }
         } else {
            if ($args{r_as_V}) {
               $ipa_seg =~ m/$VcharPlusR\b/ ; # Crucially ...\b here.
               $v_cluster[$i] = $1 ;
            } else {
               $ipa_seg =~ m/$Vchar/ ; # plain mode
               $v_cluster[$i] = $1 ;
            }
         }
      }
   }
   ## generate bigrams
   if ( $args{bigram} ) {
      my @ipa_seg_bigrams  = generate_bigrams( \@ipa_segs ) ; # Crucially \@
      my @spell_seg_bigrams = generate_bigrams( \@spell_segs ) ; # Crucially \@
      ## check
      if ( $args{debug} ) {
         foreach my $seg_bigram ( @ipa_seg_bigrams ) {
            print "# ipa_seg_bigram: $seg_bigram\n" ;
         }
         foreach my $seg_bigram ( @spell_seg_bigrams ) {
            print "# spell_seg_bigram: $seg_bigram\n" ;
         }
      }
      ## replace originals with bigrams
      if ( $args{extensive} ) {
         @ipa_segs  = ( @ipa_segs, @ipa_seg_bigrams ) ;
         @spell_segs = ( @spell_segs, @spell_seg_bigrams ) ;
      } else {
         @ipa_segs  = @ipa_seg_bigrams ;
         @spell_segs = @spell_seg_bigrams ;
      }
   }
   if ( $args{trigram} ) {
      my @ipa_seg_trigrams  = generate_trigrams( \@ipa_segs ) ; # Crucially \@
      my @spell_seg_trigrams = generate_trigrams( \@spell_segs ) ; # Crucially \@
      ## check
      if ( $args{debug} ) {
         foreach my $seg_trigram ( @ipa_seg_trigrams ) {
            print "# ipa_seg_trigram: $seg_trigram\n" ;
         }
         foreach my $seg_trigram ( @spell_seg_trigrams ) {
            print "# spell_seg_trigram: $seg_trigram\n" ;
         }
      }
      ## replace originals with bigrams
      if ( $args{extensive} ) {
         @ipa_segs  = ( @ipa_segs, @ipa_seg_trigrams ) ;
         @spell_segs = ( @spell_segs, @spell_seg_trigrams ) ;
      } else {
         @ipa_segs  = @ipa_seg_trigrams ;
         @spell_segs = @spell_seg_trigrams ;
      }
   }
   ## pair ipa-spell units
   my @paired ;
   for $i ( 0 .. ( scalar @spell_segs - 1 ) ) {
      if ( $i < scalar @ipa_segs ) {
         my $ipa_seg = $ipa_segs[$i] ;
         print "# ipa_seg$i: $ipa_seg\n" if $args{verbose} ;
      }
      if ( any { defined } ($spell_segs[$i], $ipa_segs[$i]) ) {
         $ipa_segs[$i]  = $missing if !defined $ipa_segs[$i] ;
         $spell_segs[$i] = $missing if !defined $spell_segs[$i] ;
         if ( $args{inverted} ) {
            $paired[$i] = $spell_segs[$i] . $joint . $ipa_segs[$i] ;
         } else {
            $paired[$i] = $ipa_segs[$i] . $joint . $spell_segs[$i] ;
         }
      } else {
         $paired[$i] = $void . $joint. $void ;
      }
   }
   ## construct temporary units
   $j = 0 ;
   if ( @paired == 0 ) { print $fseq ; } # gives null field value
   foreach my $pair (@paired) {
      $j++ ;
      if ( $j < @paired ) { print $pair, $vseq ; }
      else { print $pair, $fseq ; }
   }
   #my $v_list = join($v_bond, @v_cluster); # $v_cluster fails here.
   $j = 0 ;
   foreach my $v (@v_cluster) {
      if ( $args{debug} ) {
         $v = $missing if !defined $v ;
         print "\n# \$v$j: $v\n"
      }
      print $v_bond ;
      if ( defined $v ) {
         if ($j < @v_cluster ) { print $v ; }
         else { print $v_bond ; }
         $j++ ;
      }
   }
   print $v_bond ;
   print "\n" ;
}

## functions
sub generate_bigrams {
   my @A = @{ shift() } ; # Crucially
   my @B = ( ) ;
   for my $i ( 0 .. scalar @A ) {
      my $x = $A[$i] ;
      $x = $missing if !defined $x ;
      my $y = $A[$i + 1] ;
      $y = $missing if !defined $y ;
      push @B, $x.$y if ( any { defined } ($x, $y) ) ;
   }
   return @B ;
}
#
sub generate_trigrams {
   my @A = @{ shift() } ; # Crucially
   my @B = ( ) ;
   for my $i ( 0 .. scalar @A ) {
      my $x = $A[$i] ;
      $x = $missing if !defined $x ;
      my $y = $A[$i + 1] ;
      $y = $missing if !defined $y ;
      my $z = $A[$i + 2] ;
      $z = $missing if !defined $z ;
      if ( any { defined } ($x, $y, $z) ) { push @B, $x.$y.$z ; } ;
   }
   return @B ;
}

### end of script
