#!/usr/bin/env perl
#############################################################################
#
#  Title:  mushformat
#  Author: Myrddin (J. Scott Dorr)
#  Date:   10-09-95
#  
#  Usage: mushformat <filename>
#
#  This program takes an ascii file and modifies it for viewing on a MUSH
#  using the following rules, in this order:
#
#       1.  The characters [,],%,\ are 'escaped' with a \ char.
#       2.  All carriage returns are converted to %r
#       3.  Single or double spaces are replaced with %b's
#       4.  All groupings of more than 2 spaces are converted into a single
#           [space(x)] string.
#       5.  All tabs are converted to 5 spaces. Yes, this is an imperfect
#           method of dealing with tabs, but tabs have always been evil and
#           /I/ never use them, so there. :-)
#
#           You can edit the regex with the comment below if you'd like to
#           change that behavior.
#
#############################################################################

$filename = $ARGV[0] || die "Usage: mushformat <filename>\n";

open(F1,"$ARGV[0]") || die "Can't open $ARGV[0].";

while (<F1>) {
   s/((\\)|(%)|(\[)|(\]))/\\$1/g;
   s/\n/%r/g;

   # tab conversion.  edit this regex if you want to do something different
   s/\t/     /g;	## If you want to convert to %t: s/\t/%t/g;

   s/(\s{3,})/sprintf("[space(%d)]",length($&))/eg;
   s/\s\s/%b%b/g;
   $newfile = $newfile.$_;
}
close F1;

# get rid of the trailing %r that will always result (unix files have a CR at 
# the end, and this gets converted to a %r). Yes, this is faster than a
# substr - I timed it. :-)
chomp $newfile; chomp $newfile;

print "$newfile\n";
