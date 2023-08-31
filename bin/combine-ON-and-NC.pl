#!/usr/bin/env perl -w
#
# Created: 2023/08/31
# Modified: 

use strict;
use warnings;
use utf8;
#
use File::Slurp ;
use Data::Dumper qw /Dumper/;
#use List::Util qw /sum/; # provide sum (..)
#use List::MoreUtils qw/firstidx lastidx/;

## handle options
use Getopt::Long ;
my %args = ( debug => 0, verbose => 0, drop_initial_r => 0,
    ON_filter => "", NC_filter => "", drop_initial_n => 0, show_source => 0
) ;
GetOptions (\%args,
     "help|h",            # print help
     "debug|d",           # debug option
     "verbose|v",         # verbose option
     "NC_based|p",        # prepending ON to NC rather than appending NC to ON
     "drop_initial_r|r",  # drop intial /ɹ/ option
     "drop_initial_n|n",  # drop intial /ŋ/ option
     "show_source|s",     # show sources
     "ON_filter|O=s",     # specifies value for NC_filter
     "NC_filter|C=s",     # specifies value for NC_filter
) ;
print_help() if $args{help} ;

## handle implications
if ( $args{debug} ) {
    $args{verbose} = 1 ;
    $args{show_source} = 1
}
## inspection
print Dumper \%args if $args{debug} ;
print Dumper \@ARGV if $args{debug} ;
#exit;

## char encoding
use open IO => ":utf8" ;
#use open IO => ":$enc" ; # doesn't work
my $enc = "utf8" ;
binmode STDIN, ":$enc" ;
binmode STDOUT, ":$enc" ;
binmode STDERR, ":$enc" ;

# variables
my $field_sep = "[,]" ;
my $pair_sep  = ":" ;
my $spell_sep = "[/#]" ;
my $joiner1   = "\n";
my $joiner2   = ",";
my $targetN   = "" ; # global

# IPA symbol classes defned
# Class
my $ipaVclassRaw     = "əɚɜɝaɑɒæʌɛeɪiɨoɔuʊːɐœøʏɑ̃" ;
my $ipaVclass        = "[$ipaVclassRaw]" ;
my $ipaClassNucleus  = "[$ipaVclassRaw]+" ; # used for ONC composition
my $ipaClassOnset    = "[^$ipaVclassRaw]+" ;
my $ipaClassCoda     = "[^$ipaVclassRaw]+" ;
# Vowel cluster
my $ipaVcluster       = "([$ipaVclassRaw]+)" ;
my $ipaVclusterPlusJ  = "([j$ipaVclassRaw]+)" ;
my $ipaVclusterPlusH  = "([h$ipaVclassRaw]+)" ;
my $ipaVclusterPlusR  = "([$ipaVclassRaw]+|ɹ)" ;  # picks up /ɹ/ alone successfully
my $ipaVclusterPlusHR = "([h$ipaVclassRaw]+|ɹ)" ;
#
# word character classes defined
my $charVcluster        = "(y|[aeiouäöüAEIOUÄÖÜ][aeiouyäöüAEIOUÄÖÜ]*)" ;
#my $charVclusterPlusX   = "(y|['aeiouw]+)" ; # incompatible with wh-words
my $charVclusterPlus    = "(y|[aeiouäöüAEIOUÄÖÜ]+[aeiouywäöüAEIOUÄÖÜ]*)" ;
my $charVclusterPlusY   = "(y|[aeiouäöüAEIOUÄÖÜ]+[ywäöüAEIOUÄÖÜ]*)" ;

### main

## load files
my $ON_file = shift ;
my $NC_file = shift ;
print $ON_file if $args{show_source} ;
print $NC_file if $args{show_source} ;

## load ON data
my $ON_raw = read_file( $ON_file, binmode => ":$enc" ) ; # requires File::Slurp
my @ON_lines = split "\n", $ON_raw ; # better to be here
if ( $args{ON_filter} )  {
   @ON_lines = grep { $_ =~ /$args{ON_filter}/ } @ON_lines ;
}
#print Dumper \@ON_lines if $args{debug} ;
my @ON_data = map { split /[\s\t]+/, $_  } @ON_lines ;
print Dumper \@ON_data if $args{debug} ;
@ON_data = map { $_ =~ /:/ ? ($_) : ( ) } @ON_data ; # Crucial use of ifelse-equivalent

##  
if ( $args{drop_initial_r} ) {
    # removes extraneous [r] first
    @ON_data = map { $_ =~ /^ɹ/ ? ( $_ =~ s/:w?ɹh?/:/ ) : ( $_ ) } @ON_data ;
    # removes extraneous /ɹ/ next
    @ON_data = map { $_ =~ /^ɹ/ ? ( $_ =~ s/^ɹ// ) : ( $_ ) } @ON_data ;
}
##
if ( $args{drop_initial_n} ) {
    # removes extraneous [n] first
    @ON_data = map { $_ =~ /^ŋ/ ? ( $_ =~ s/:n/:/ ) : ( $_ ) } @ON_data ;
    # removes extraneous /ŋ/ next
    @ON_data = map { $_ =~ /^ŋ/ ? ( $_ =~ s/^ŋ// ) : ( $_ ) } @ON_data ;
}
print Dumper \@ON_data if $args{debug} ;

## load NC data
my $NC_raw = read_file( $NC_file, binmode => ":$enc" ) ; # requires File::Slurp
my @NC_lines = split "\n", $NC_raw ; # better to be here
if ( $args{NC_filter} )  {
   @NC_lines = grep { $_ =~ /$args{NC_filter}/ } @NC_lines ;
}
#print Dumper \@NC_lines if $args{debug} ;
my @NC_data = map { split /[\s\t]+/, $_  } @NC_lines ;
print Dumper \@NC_data if $args{debug} ;
#@NC_data = map { $_ =~ /:/ ? ($_) : ( ) } @NC_data ; # Crucial use of ifelse-equivalent
@NC_data = grep { $_ =~ /:/ } @NC_data ;
print Dumper \@NC_data if $args{debug} ;

## combine ON and NC data
if ( $args{NC_based} ) {
    ## process over NC lines
    foreach my $NC ( @NC_data ) {
        print "# processing \$NC: $NC\n" if $args{verbose} ;
        # sound match for Necleus
        my @ON_matches = &find_ON_matches ($NC) ;
        printf "# found %d \@ON_matches: @ON_matches\n", (scalar @ON_matches) if $args{verbose} ;
        ## compose ON and NC
        foreach my $ON ( @ON_matches ) {
            print "# \$ON: $ON\n" if $args{debug} ;
            my $ONC = &merge_ON_and_NC ( $ON, $NC ) ;
            print "$ONC\n" ;
        }
    }
} else {
    ## process over ON lines
    foreach my $ON ( @ON_data ) {
        print "# processing \$ON: $ON\n" if $args{verbose} ;
        # sound match for Necleus
        my @NC_matches = &find_NC_matches ($ON) ;
        printf "# found %d \@NC_matches: @NC_matches\n", (scalar @NC_matches) if $args{verbose} ;
        ## compose ON and NC
        foreach my $NC ( @NC_matches ) {
            print "# \$NC: $NC\n" if $args{debug} ;
            my $ONC = &merge_ON_and_NC ($ON, $NC) ;
            print "$ONC\n" ;
        }
    }
}

### functions
sub find_NC_matches {
    my @matchedNC = ( ) ;
    my $key_ON = shift ;
    print "# \$key_ON: $key_ON\n" if $args{debug} ;
    $key_ON =~ /($ipaClassNucleus):/ ;
    $targetN = $1 ;
    if ( defined $targetN ) {
        print "# \$targetN: $targetN\n" if $args{debug} ;
        #my @matched = grep { $_ =~ /($ipaClassOnset)*$targetN:/ } @NC_data ;
        my @matched = grep { $_ =~ /^$targetN($ipaClassCoda)*:/ } @NC_data ;
        printf "# \@matched: %s\n", ( join $joiner2, @matched ) if $args{debug} ;
        push @matchedNC, @matched ;
    }
    return @matchedNC ;
}
##
sub find_ON_matches {
    my @matchedON = ( ) ;
    my $key_NC = shift ;
    print "# \$key_NC: $key_NC\n" if $args{debug} ;
    $key_NC =~ /^($ipaClassNucleus)/ ;
    $targetN = $1 ;
    if ( defined $targetN ) {
        print "# \$targetN: $targetN\n" if $args{debug} ;
        my @matched = grep { $_ =~ /($ipaClassOnset)*$targetN:/ } @ON_data ;
        printf "# \@matched: %s\n", ( join $joiner2, @matched ) if $args{debug} ;
        push @matchedON, @matched ;
    }
    return @matchedON ;
}

##
sub merge_ON_and_NC {
    my $yON = shift ;
    my $yNC = shift ;
    my ($ON_sound, $ON_spell) = split $pair_sep, $yON;
    my ($NC_sound, $NC_spell) = split $pair_sep, $yNC;
    if ( $args{debug} ) {
        print "# \$NC_sound: $NC_sound\n" ;
        print "# \$NC_spell: $NC_spell\n" ;
    } 
    $NC_sound =~ s/^$ipaVcluster// ;
    $NC_spell =~ s/^$charVcluster// ;
    if ( $args{debug} ) {
        print "# \$NC_sound 2: $NC_sound\n" ;
        print "# \$NC_spell 2: $NC_spell\n" ;
    } 
    my $sound = $ON_sound . $NC_sound;
    my $spell = $ON_spell . $NC_spell;
    ## corrections to overapplications
    $spell =~ s/([w])+/$1/g ; # removews sequences like ww..
    #$spell =~ s/([o])+([w])/$1$2/g ; # removews sequences like ww..
    return $sound . $pair_sep . $spell ;
}

### end of script
