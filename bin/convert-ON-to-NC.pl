#!/usr/bin/env perl -w
#
# Created: 2023/05/26
# Modified
# 2023/08/07: implemented reorder2, a simpler and better implementation
# 2023/08/09, 10: added conversion routine for spelling
# 2023/08/10: added patches to handle lawyer; added /y/ to ipaVchar classes
# 2023/08/21: revised finalization patches; changed treatment of [j]

use strict;
use warnings;
use utf8;
use open IO => ":utf8" ;
#use open IO => ":$enc" ; # doesn't work
my $enc = "utf8" ;
binmode STDIN, ":$enc" ;
binmode STDOUT, ":$enc" ;
binmode STDERR, ":$enc" ;
#use List::MoreUtils qw/firstidx lastidx/;

# handle options
use Getopt::Long ;
my %args = ( debug => 0, verbose => 0, reorder => 1, unpatch => 0 ) ;
GetOptions(\%args,
   "help|h",     # print help
   "debug|d",    # debug option
   "verbose|v",  # verbose option
   "unpatch|p",    # disable patch option
   "reorder|r"   # disable reorder option
);
print_help() if $args{help} ;

## handle implications
if ( $args{debug} ) { $args{verbose} = 1 ; }

# variables
my $field_sep = "[,]" ;
my $spell_sep = "[/#]" ;

# IPA symbol classes defned
my $ipaVchar       = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+)" ;
my $ipaVcharPlusJ = "([jəɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+)" ;
my $ipaVcharPlusH  = "([həɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+)" ;
my $ipaVcharPlusR  = "([əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+|ɹ)" ;  # picks up /ɹ/ alone successfully
my $ipaVcharPlusHR = "([həɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃]+|ɹ)" ;

# word character classes defined
my $Vchar      = "(y|[aeiouäöüAEIOUÄÖÜ][aeiouyäöüAEIOUÄÖÜ]*)";
#my $VcharPlusX  = "(y|['aeiouw]+)"; # incompatible with wh-words
my $VcharPlus  = "(y|[aeiouäöüAEIOUÄÖÜ]+[aeiouywäöüAEIOUÄÖÜ]*)";
my $VcharPlusY  = "(y|[aeiouäöüAEIOUÄÖÜ]+[ywäöüAEIOUÄÖÜ]*)";

## main
while ( my $line = <> ) {
   next if ( $line =~ /^[%]/ or $line =~ /^\n/); # Note # has a specific purpose
   # remove comment
   $line = $line =~ s/(.+)[ \t]*%.*/$1/r;
   print "# line: $line\n" if $args{debug};
   # split into fields
   chomp $line;
   # get field values
   my (@fields, $sound, $spell);
   @fields = split /$field_sep/, $line;
   print "# \@fields: @fields\n" if $args{debug};
   if ( $fields[0] =~ /^\d+$/ ) {
      $sound  = $fields[1]; $spell  = $fields[2];
   } else {
      $sound  = $fields[0]; $spell  = $fields[1];
   }
   print "# \$sound: $sound\n" if $args{debug};
   print "# \$spell: $spell\n" if $args{debug};
   ## convert sound
   #$sound =~ s/\W+//ig; # this turned out to be offensive
   print "# \$sound: $sound\n" if $args{verbose};
   my %result1 = analyze_sound ($sound);
   #
   my @cv_list1 = @{ $result1{cv_list} };
   printf "# cv_list1: @cv_list1\n" if $args{debug};
   my @x_list1 = @{ $result1{x_list} };
   #printf "# x_list1: @x_list1\n" if $args{debug};
   my @encoding1 = @{ $result1{encoding} };
   #printf "# \@encoding1: @encoding1\n" if $args{debug};
   my @reordered1 = reorder_sound ([@encoding1]);
   print "# \@reordered1: @reordered1\n" if $args{debug};
   my @filled1;
   if ( $args{reorder} ) {
      @filled1 = fill ( [@reordered1], [@cv_list1], [@x_list1] );
   } else {
      @filled1 = fill ( [@encoding1], [@cv_list1], [@x_list1] );
   }
   ## convert spell
   print "# \$spell: $spell\n" if $args{verbose};
   my %result2 = analyze_spell ($spell);
   #
   my @cv_list2 = @{ $result2{cv_list} };
   printf "# cv_list2: @cv_list2\n" if $args{debug};
   my @x_list2 = @{ $result2{x_list} };
   #printf "# x_list2: @x_list2\n" if $args{debug};
   my @encoding2 = @{ $result2{encoding} };
   #printf "# \@encoding2: @encoding2\n" if $args{debug};
   my @reordered2 = reorder_spell ([@encoding2]);
   print "# \@reordered2: @reordered2\n" if $args{debug};
   my @filled2;
   if ( $args{reorder} ) {
      @filled2 = fill ( [@reordered2], [@cv_list2], [@x_list2] );
   } else {
      @filled2 = fill ( [@encoding2], [@cv_list2], [@x_list2] );
   }
   # output
   my $filled1 = join "", @filled1;
   my $filled2 = join "", @filled2;
   $filled2 = patch ( $filled2 ) unless $args{unpatch};
   printf "%s,%s\n", $filled1, $filled2;
   print "----\n" if $args{debug};
}

## functions
#
sub get_indices {
   my $v = shift @_;    # key to look for
   my @A = @{shift @_}; # array to look for the key
   my @indices = ( ) ;
   map { push @indices, $_ if ( $A[$_] == $v ); } ( 0..scalar @A ) ;
   return @indices;
}
#
sub analyze_sound {
   my $sound = shift @_;
   $sound = $sound =~ s/ +//r; # removes spaces; /ig fals to work
   my ( @cv_list, @x_list, @encoding );
   for my $c ( split "", $sound ) {
      print "# c: $c\n" if $args{debug};
      if ( $c =~ /[#012-]/ ) {
         push @x_list, $c; push @encoding, "x";
      } else {
         push @cv_list, $c;
         if ( $c =~ /$ipaVchar/ ) { push @encoding, "v"; }
         else { push @encoding, "c"; }
      }
   }
   # returns a hash
   my %H;
   $H{cv_list}  = \@cv_list;
   $H{x_list}   = \@x_list;
   $H{encoding} = \@encoding;
   return %H;
}
#
sub reorder_sound {
   my $arg =  shift;
   my @encoding = @{ $arg };
   print "# \@encoding: @encoding\n" if $args{debug};
   my $xcount = scalar (grep { $_ eq "x" } @encoding);
   print "# \$xcount: $xcount\n" if $args{debug};
   my $reordered = join "", @encoding;
   my $j;
   for ($j = 0; $j < $xcount; $j++) {
      $reordered =~ s/(c*)(v+)x(c*)/$1x$2y$3/; # Crucial trick with adding y
      print "# \$reordered $j: $reordered\n" if $args{debug};
   }
   # remove y's
   $reordered =~ s/y//g;
   #
   my @reencoded = split "", $reordered;
   return @reencoded;
}
#
sub analyze_spell {
   my $spell = shift @_;
   $spell = $spell =~ s/ +//r; # removes spaces; /ig fals to work
   my (@cv_list, @x_list, @encoding);
   for my $c ( split "", $spell ) {
      print "# c: $c\n" if $args{debug};
      #if ( $c eq  "/" or $c eq "#" ) { # offensive if # is treated properly
      if ( $c eq  "/" ) { # treat # as consonant
         push @x_list, $c; push @encoding, "x";
      } else {
         push @cv_list, $c;
         if ( $c =~ /$VcharPlus/ ) { push @encoding, "v"; }
         else { push @encoding, "c"; }
      }
   }
   # returns a hash
   my %H;
   $H{cv_list}  = \@cv_list;
   $H{x_list}   = \@x_list;
   $H{encoding} = \@encoding;
   return %H;
}
#
sub reorder_spell {
   my $arg =  shift;
   my @encoding = @{ $arg };
   print "# \@encoding: @encoding\n" if $args{debug};
   my $xcount = scalar (grep { $_ eq "x"  } @encoding);
   print "# \$xcount: $xcount\n" if $args{debug};
   my $reordered = join "", @encoding;
   #if ( $reordered =~ /^v/ ) { $reordered = "x".$reordered; } # offensive
   my $j;
   for ($j = 0; $j < $xcount; $j++) {
      # Crucial trick with adding y, (v+c?)x
      $reordered =~ s/(c*)(v+)x(c*)/$1x$2y$3/;
      print "# \$reordered $j: $reordered\n" if $args{debug};
   }
   # remove y's
   $reordered =~ s/y//g;
   my @reencoded = split "", $reordered;
   return @reencoded;
}
#
sub fill {
   #foreach my $arg ( @_ ) {
   #   print "# \$arg: $arg\n" if $args{debug};
   #}
   my @template = @{shift @_};
   print "# template: @template\n" if $args{debug};
   my @cv_list = @{shift @_};
   print "# cv_list: @cv_list\n" if $args{debug};
   my @x_list = @{shift @_};
   print "# x_list: @x_list\n" if $args{debug};
   #
   my @filled = ();
   my $val = "";
   foreach my $t ( @template ) {
      print "# t: $t\n" if $args{debug};
      if ( $t eq 'x' ) {
         $val = shift @x_list;
         if (defined $val) { push @filled, $val; }
      } else {
         $val = shift @cv_list; push @filled, $val;
      }
   }
   return @filled;
}
# handles exceptional cases evading from systematic treatment
sub patch {
   my $spellx = shift;
   # corrections to apply
   ## y-ending cases
   $spellx =~ s|/ry|r/y|g; # inevitable
   $spellx =~ s|/ev/ery|/ever/y|g;
   ## u-ending cases
   $spellx =~ s|([qkg])/u([aeiou])|$1u/$2|g;
   ## r-ending cases
   $spellx =~ s|/y([ae])r|y/$1r|g;
   #$spellx =~ s|/yer|y/er|g;
   $spellx =~ s|er/(p[^aeiou])|/er$1|g; # likely to be offensive
   $spellx =~ s|ear/([^yaou]*)|ea/r$1|g; # exclude cases like fai/r/y, hai/r/y
   $spellx =~ s|eir/|ei/r|g;
   $spellx =~ s|air/([^y]*)|ai/r$1|g; # exclude cases like fai/r/y, hai/r/y
   $spellx =~ s|/our/|/ou/r|g;
   ## re-ending cases
   #$spellx =~ s|/(u?[aiuo])r/e(/?)|/$1/re$2|g; # offensive for directory
   $spellx =~ s|/q(u?[aiuo])r/e(/?)|q/$1/re$2|g;
   $spellx =~ s|/i/(re[dm])|/i/$1|g;
   $spellx =~ s|/([ie])r/e|/$1/re|g;
   ## w-ending cases
   #$spellx =~ s|aw/|/aw|g;
   #$spellx =~ s|ow/|/ow|g;
   #$spellx =~ s|ew/([^aeiou]*)|/ew$1|g;
   $spellx =~ s|([aeo]?)w/([^aeiou]\|$)|/$1w$2|g;
   $spellx =~ s|/([yw])([aeiou])|$1/$2|g;
   ## h-ending cases
   $spellx =~ s|([aeiouy]+h)/([^aeiouy])|/$1$2|g; # effective generalization
   #$spellx =~ s|^uh/$|/uh|g;
   ##$spellx =~ s|eh/|/eh|g; # offensive
   ##$spellx =~ s|w(o?e)(h[^aeiou])/|w/$1$2|g;
   #$spellx =~ s|(o?e)(h[^aeiou])/|$1/$2|g;
   ##$spellx =~ s|oeh/|/oeh|g;
   #$spellx =~ s|oe/h|/oeh|g;
   ##$spellx =~ s|oh/|/oh|g; # offensive
   #$spellx =~ s|([kgcjsz]\|^)oh/|$1/oh|g;
   ##$spellx =~ s|oh/(n?)|/oh$1|g;
   ##$spellx =~ s|(e?a)h/|/$1h|g; # offensive
   #$spellx =~ s|ah/|/ah|g;
   ##$spellx =~ s|eah/|/eah|g;
   ##
   $spellx =~ s|o'/l|/o'l|g;
   $spellx =~ s|y'/k|y/'k|g;
   # revert overapplication
   $spellx =~ s|o/ne|/one|g;
   $spellx =~ s|ow/e$|/owe|g;
   $spellx =~ s|o/reig|or/eig|g;
   $spellx =~ s|/reer/|r/ee/r|g;
   $spellx =~ s|/reer|r/eer|g;
   $spellx =~ s|//aw|/aw/|g;
   $spellx =~ s|//ew|/ew/|g;
   $spellx =~ s|//ow|/ow/|g;
   $spellx =~ s|//eh|/e/h|g;
   $spellx =~ s|y/e$|/ye|g;
   $spellx =~ s|yeah/|y/eah|g;
   $spellx =~ s|ye/ah/|y/eah|g;
   $spellx =~ s|b/us/ine|b/usin/e|g;
   $spellx =~ s|/i/rec/|/ir/ec/|g;
   $spellx =~ s|a/rabl|ar/abl/|g; # cares unbearable
   #
   return $spellx;
}

### end of script
