#!/usr/bin/env perl
# vim:tw=99999:ts=4:shiftwidth=4
#############################################################################
#
#  Title:  mcode.pl
#  Author: Myrddin (J. Scott Dorr)
#  Date:   unknown (early 00's?)
#          updated 2020: differential updates, etc
#
#  This script can take a file of formatted MUSH code and smoosh it down to
#  single blocks of text per attribute so that it can be safely quoted/pasted
#  to a MUSH.  This allows coders to write MUSH code in a more natural style.
#
#  Besides appropriate and useful line breaks, indents, blank lines, etc, you
#  can also include inline MUSH-style comments (lines beginning with '@@ ').
#  You can put line breaks whereever you'd like, as long as you keep in mind the
#  following:
#
#
#  TIGHT LINE JOINS:
#
#       When mcode.pl joins lines together, it does it 'tightly' ... it will not
#       try to place a space between those joined lines.
#
#
#  Usage:       mcode.pl [-p] -f <filename>
#  Inside tf:   /quote -S !"cat /path/to/my_formatted_code_file | ~/bin/mcode.pl -f %*"
#
#  tf tip: 
#       Create a macro in tf to allow you to /quote code from a commonly used
#       location easily:
#
#               /def qc = /quote -S !"cat ~/mush/code/%* | ~/bin/mcode.pl -f %*"
#
#       Then, I just need to:  /qc mycodefile
#       and the file with all my easy to read formatted MUSH code is piped
#       through mcode.pl, on the fly, before being /quote'd to the MUSH.
#
#
# DIFFERENTIAL UPDATES: -p
#     
#       When mcode.pl processes a file for sending to a game, it stores a copy of the processed code file in /tmp.
#       Subsequent processing of the same file can do a differential output if mcode.pl is given the -p (partial) flag. 
#       This can be helpful if you're working on a particularly large file and don't want to be sending hundreds of
#       lines every time you make a simple code change.  We can take the tf example above and create new macro to use 
#       the -p flag for a 'partial' code quote:
#
#               /def qcp = /quote -S !"cat ~/mush/code/%* | ~/bin/mcode.pl -p -f %*"
#
#
#     
#
# EXAMPLE
#
# A file can have text like the following:
#
# @@ trigger exit messages: 
# @@    set sane default succ/osucc/odrop on exit
# @@    based on its cardinal direction
# &tr_exitmsgs #134=@switch u(fn_is_cardinal_dir,%0)=
#                   0,{@pemit %1=%t:: [name(%0)] (%0) is not an exit to check},
#                   @@ default case
#                     {
#                        @pemit %1=%t:: Checking out exit [name(%0)] (%0);
#                        th setq(+,lcstr(v(d_dirname_[u(fn_dirname_from_displayname,name(%0))])),dirname);
#                        @succ %0=%%rYou head %q<dirname>.;
#                        @osucc %0=heads %q<dirname>.;
#                        @odrop %0=arrives from the [lcstr(v(d_dirname_[u(fn_rdir,left(%q<dirname>,1))]))].
#                     }
#
# 
# mcode.pl will convert it to:
#
# &tr_exitmsgs #134=@switch u(fn_is_cardinal_dir,%0)=0,{@pemit %1=%t:: [name(%0)] (%0) is not an exit to check},{@pemit %1=%t:: Checking out exit [name(%0)] (%0);th setq(+,lcstr(v(d_dirname_[u(fn_dirname_from_displayname,name(%0))])),dirname);@succ %0=%%rYou head %q<dirname>.;@osucc %0=heads %q<dirname>.;@odrop %0=arrives from the [lcstr(v(d_dirname_[u(fn_rdir,left(%q<dirname>,1))]))].}
#
#############################################################################
use Getopt::Std;

$debug = 0;
$patch = 0;

$blankline = 0;
$standalone = 0;
$ts = time();

my %opts=();
getopts("pdf:", \%opts);

$debug = 1 if defined $opts{d};
$patch = 1 if defined $opts{p};
if (defined $opts{f}) {
    $fnf = $opts{f}; #  || die "@pemit me=Required: -f <code file>\n";
}
else {
    $standalone = 1;
}

if ($patch) { $full_file = 0; }
       else { $full_file = 1; }

@p = split '/', $fnf;
$fn = $p[-1];

&print_mush("Attempting to open file") if $debug;
if ($standalone) {
    open $fh, '>>&=', fileno(STDOUT);
}
else {
    open($fh,">/tmp/${fn}_mcode_${ts}") or die "\@pemit me=Unable to open ${fn}_mcode_${ts} for writing\n";
}

while($l = <STDIN>)
{
   # &print_mush("Got a line");
   chomp $l;
print $fh "@@ got a line\n" if $debug;
   if ($l =~ /^$/) {
      $blankline++;
      next;
   }

print $fh "@@ not a blank line\n" if $debug;

   if ($l =~ /^@@/) {
      # comment in the file
      next;
   }

   # something other than whitespace.  this is the start of a new line of code
   if ($l =~ /^\S/) {
      if ($codeline) {
         print $fh $codeline, "\n";
         $prev_codeline = $codeline;
      }
      &print_blanklines();
      $codeline = $l;
      next;
   }

print $fh "@@ not an new line of code\n" if $debug;

   # must be an extension of the current code line
   if ($codeline) {
      my $tmp = $l;
      $tmp =~ s/^\s+//;
      $tmp =~ s/\s+$//;

      if ($tmp eq '@@' or $tmp =~ /^@@ /) {
         # inline comment.  ignore entirely
      }
      else {
         $codeline .= $tmp;
      }
   }
   else {
      # huh?
      print $fh "@@ ERROR: poorly formatted mush test file at line: ($l)\n";
   }

   $blankline = 0;
}

if ($codeline ne $prev_codeline) {
    print $fh $codeline, "\n";
}

if ($standalone) {
    exit;
}

&print_mush("done with file") if $debug;
close $fh;

# compare to previous file, if it exists.  only send diffs
# otherwise, send entire file
@files = `ls -rt /tmp/${fn}_mcode_* | tail -2`;
$num_files = @files;
chomp @files;
if ($full_file or ($num_files < 2)) {
    if ($debug) {
        foreach $f (@files) {
            print "found: $f\n";
        }
    }
    # just the one file, then
    $codefile = $files[-1]; # last member of the array in case we're here for full_file
    open(F1,$codefile);
    while (<F1>) {
        print;
    }
}
else {
    # diff --unchanged-line-format= --old-line-format= --new-line-format='%L' /tmp/rdesc_mcode_1580441937 /tmp/rdesc_mcode_1580441998
    $diff_cmd = 'diff --unchanged-line-format= --old-line-format= --new-line-format=\'%L\'';
    $diff_cmd = 'diff --unchanged-line-format= --old-line-format= --new-line-format=%L';
    @diffs = `$diff_cmd --from-file=$files[0] $files[1]`;
    $num_diffs = @diffs;

    print '@set me=quiet' . "\n";
    foreach $diff (@diffs) {
        if ($diff =~ /^$/) {
            $num_diffs--;
            next;
        }
        print $diff;
        @words = split ' ', $diff;
        &print_mush($words[0]);
    }
    print '@set/quiet me=!quiet' . "\n";

    if ($num_diffs == 1) { $line_str = 'line'; }
                    else { $line_str = 'lines'; }
    &print_mush("$num_diffs $line_str sent");

    # clean up of old files
    @files = `ls -rt /tmp/${fn}_mcode_*`;
    $num_files = @files;
    if ($num_files > 2) {
        pop @files;
        pop @files;
        foreach my $f (@files) {
            system "cd /tmp; rm $f";
        }
    }
}



&print_blanklines();
if ($codeline) {
   print F1 $codeline, "\n";
}

sub print_mush()
{
    my $line = shift;
    print "th mcode:: $line\n";
}

sub print_blanklines()
{
   $bls = "\n" x $blankline;
   $blankline = 0;

   print F1 $bls;
}
