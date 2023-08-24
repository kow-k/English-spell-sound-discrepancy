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
# 2023/08/10: added /y/ to Vchar classes
# 2023/08/22: added /j/ to Vchar classes, modified to handle IPA symbols for German 
# 2023/08/24: revised V matching to allow for N with tailing /ɹ/ in NC mode

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

## variables and constants
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
my $missing = "";

## IPA matching conditions
my $Vchar       = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+)" ;
my $VcharPlusH  = "(h?[əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+)" ;
my $VcharPlusR  = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+ɹ?)" ;
my $VcharPlusR2  = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+|ɹ)" ;  # picks up /ɹ/ alone successfully
my $VcharPlusHR = "(h?[əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+ɹ?)" ;
my $VcharPlusHR2 = "(h?[əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+ɹ?|ɹ)" ;

## options
my %args = ( debug => 0, verbose => 0, r_as_V => 0, h_as_V => 0, mark_missing => 0 );
GetOptions(\%args,
   "help",           # print help
   "debug|d",        # runs in debug mode
   "verbose|v",      # runs in verbose mode
   "r_as_V|r",       # treats [ɹ] as a vowel, effective in NC mode
   "h_as_V|h",       # treats [h] as a vowel, effective in ON mode
   "inverted|i",     # inverts ipa-spell order in pairing
   "unstrip|u",      # retains stress-marks and slashes
   "mark_missing|m", # insert '_' for missing character
   "bigram|b",     # runs in bigram mode
   "trigram|t",    # runs in bigram mode
   "extensive|e"   # bigrams extend unigrams
) ;

## handle implications
if ( $args{debug} ) { $args{verbose} = 1 ; }
if ( $args{mark_missing} ) { $missing = "_" ;}

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
   ## get IPA segments
   my @ipa_segs = split /$ipa_sep/, $ipa ; # added # later
   if ( $args{debug} ) {
      print "\n" ;
      for my $i ( 0 .. @ipa_segs ) {
         print "# ipa_seg$i: $ipa_segs[$i]\n" if defined $ipa_segs[$i];
      }
   }
   ## get spell segments
   my @spell_segs = split $spell_sep, $slashed ; # added # later
   if ( $args{debug} ) {
      #for my $spell_seg ( @spell_segs ) { print "# spell_seg: $spell_seg\n" ; }
      for my $i ( 0 .. @spell_segs ) {
         print "# spell_seg$i: $spell_segs[$i]\n" if defined $spell_segs[$i] ;
      }
   }
   ## define vowel sequence, @v_cluster
   #my @ipa_segs_orig = @ipa_segs ; # stored for vowel sequence generation
   #my @spell_segs_orig = @spell_segs ;
   my @v_cluster ;
   for my $k ( 0 .. @ipa_segs ) {
      print "# \$k: $k" if $args{debug};
      my $ipa_seg = $ipa_segs[$k] ;
      if ( defined $ipa_seg ) {
         print "# ipa_seg: $ipa_seg\n" if $args{verbose} ;
         if ( $args{h_as_V} ) {
            if ( $args{r_as_V} ) {
               $ipa_seg =~ m/$VcharPlusHR/ ; # Crucially ...\b here.
               if ( defined $1 ) {
                  $v_cluster[$k] = $1 if ( $1 =~ /$VcharPlusHR/ );
               } 
            } else {
               $ipa_seg =~ m/$VcharPlusH/ ;
               if ( defined $1 ) {
                  $v_cluster[$k] = $1 if ( $1 =~ /$VcharPlusH/ );
               } 
            }
         } else {
            if ( $args{r_as_V} ) {
               $ipa_seg =~ m/$VcharPlusR/ ; # Crucially ...\b here.
               if ( defined $1 ) {
                  $v_cluster[$k] = $1 if ( $1 =~ /$VcharPlusR/ ) ;
               }
            } else {
               $ipa_seg =~ m/$Vchar/ ; # plain mode }
               if ( defined $1 ) {
                  $v_cluster[$k] = $1 if ( $1 =~ /$Vchar/ ) ;
               }
            }
         }
         #$v_cluster[$k] = $1 ; returns digits like "1", "2"
      }
   }
   print "# \@v_cluster: @v_cluster\n" if $args{debug};
   ##
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
