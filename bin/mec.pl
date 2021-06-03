#!/usr/bin/perl
#
# MEC - Mushcode Expander / Compressor
#
#   This script takes mushcode and attempts to make it more readable
#   by splitting single lines across multiple lines. Various arbitrary
#   rules are used to split up commands and functions.
#
#   Conversion back into a MUSH appropriate form is supported and is
#   done so without loss of characters from the original. I.e. If the
#   mushcode is "formated" and then "unformated", the output should be
#   the same as the original mushcode.
#
#   Command line usage may be optained by running this script without any
#   arguements.
#
# cmhudson@gmail.com
#
use strict;
use Text::Wrapper;
use Carp;
my $max = 75;
my $DEBUG = 0;
my %arg;
$| = 1;

#
# handle certain commands differently then the default
#
my %fmt_cmd = (
   '@switch'  => sub { fmt_switch(@_);   },
   '@select'  => sub { fmt_switch(@_);   },
   '@dolist'  => sub { fmt_dolist(@_);   },
   '&'        => sub { fmt_amper(@_);    },
   '@while'   => sub { fmt_while(@_);    },
   'think'    => sub { fmt_default(@_);  },
   '@pemit'   => sub { fmt_equal(@_);    },
   '@wait'    => sub { fmt_equal(@_);    },
   '@edit'    => sub { fmt_equal(@_);    },
);

#
# valid command line options
#
my %valid = (
   format     => "Format MushCode into multiple lines for readability",
   unformat   => "Unformat MushCode into mush readable format.",
   one        => "Mushify input for using in a say command",
   multi      => "Mushify input for quoting in multipe lines"
);

sub code
{
   my $type = shift;
   my @stack;

   if(!$type || $type eq "short") {
      for my $line (split(/\n/,Carp::shortmess)) {
         if($line =~ / at ([^ ]+) line (\d+)/) {
            push(@stack,$2);
         }
      }
      return join(',',@stack);
   } else {
      return Carp::shortmess;
   }
}

#
# ansi_add
#   Add a character or escape code to the data array. Every add of a
#   character results in a new element, escape codes are added to existing
#   elements as long as a character has not been added yet. The ansi state
#   is also kept track of here.
#
sub ansi_add
{
   my ($data,$type,$txt) = @_;

   my $ch   = $$data{ch};                      # make things more readable
   my $code = $$data{code};
   my $snap = $$data{snap};

   if($#$ch == -1 || $$ch[$#$ch] ne undef) {
      $$ch[$#$ch+1] = undef;
      $$code[$#$ch] = [];
      $$snap[$#$ch] = [];
   }

   if($type) {
     for my $c (split(//,$txt)) {                 # add multiple characters
        $$ch[ $#$ch + ((@$ch[$#$ch] ne undef) ? 1 : 0) ] = $c;
        @$code[$#$ch] = [] if(!defined @$code[$#$ch]);
        @$snap[$#$ch] = [ @{@$data{state}} ];
     }
   } else {                                           # add escape sequence
      push(@{$$code[$#$ch]},$txt);
      if($txt eq "\e[0m") {
         $$data{state} = [];
      } else {
         push(@{$$data{state}},$txt);
      }
   }
}


#
# ansi_substr
#    Do a substr on a string while preserving the escape codes.
#
#    no-ansi flag : do not copy over escape sequences
#
sub ansi_substr
{
   my ($txt,$start,$count,$noansi) = @_;
   my ($result,$data);
   my $last = -1;

   if(ref($txt) eq "HASH") {
      $data = $txt;
   } else {
      $data = ansi_init($txt);
   }

   $start = 0 if($start !~ /^\s*\d+\s*$/);                  # sanity checks
   if($count !~ /^\s*\d+\s*$/) {
      $count = ansi_length($txt);
   } else {
      $count += $start;
   }
   return undef if($start < 0);                         # no starting point

   # loop through each "character" w/attached ansi codes
   for(my $i = $start;$i < $count && $i <= $#{$$data{ch}};$i++) {
      if(!$noansi) {
         my $code=join('',@{@{$$data{($i == $start) ? "snap" : "code"}}[$i]});
         $result .= $code . @{$$data{ch}}[$i];
      } else {
         $result .= @{$$data{ch}}[$i];
      }
      $last = $#{@{$$data{snap}}[$i]};
   }

   # are attributes turned on on last character? if so, reset them.
   return $result . (($last == -1) ? "" : (chr(27) . "[0m"));
}

#
# ansi_length
#    Return the length of a string without counting all those pesky escape
#    codes.
#
sub ansi_length
{
   my $txt = shift;
   my $data = shift;

   if(ref($txt) eq "HASH") {                           # already inited txt?
      $data = $txt;
   } else {
      $data = ansi_init($txt);
   }

   if($#{$$data{ch}} == -1) {                                       # empty
      return 0;
   } elsif(@{$$data{ch}}[-1] eq undef) {               # last char pos empty?
      return $#{$$data{ch}};
   } else {
      return $#{$$data{ch}} + 1;                        # last char populated
   }
}

#
# ansi_remove
#    remove any escape codes from the string
#
sub ansi_remove
{
#   my $txt = ansi_init(shift);
#   return ansi_print($txt,0);

   my $txt = shift;
   $txt =~ s/\e\[[\d;]*[a-zA-Z]//g;
   return $txt;
}


#
# ansi_init
#    Read in a string and convert it into a data structure that can be
#    easily parsed / modified, i hope.
#
#     {
#       code => [ [ array of arrays containing escape codes ] ]
#       ch   => [ Array containing each character one by one ]
#       snap => [ [ array of arrays containing all active escape codes
#                   at the time the character was encountered ] ]
#       state=> [ internal, current state of active escape does ]
#     }
#
sub ansi_init
{
   my $str = shift;

   my $data = { ch => [], code => [], state  => [], snap   => [] };

   while($str =~ /\e\[([\d;]*)([a-zA-Z])/) {
      $str = $';
      ansi_add($data,1,$`) if $` ne undef;
      ansi_add($data,0,"\e[$1$2");
   }
   ansi_add($data,1,$str) if($str ne undef);

   return $data;
}


#
# ansi_string
#    Take ansi data structure and return
#        type => 0 : everything but the escape codes
#        type => 1 : original string [including escape codes]
#
sub ansi_string
{
   my ($data,$type) = @_;
   my $buf;

   for my $i (0 .. $#{$$data{ch}}) {
      $buf .= join('', @{@{$$data{code}}[$i]}) if($type);
      $buf .= @{$$data{ch}}[$i];
   }
   return $buf;
}

#
# ansi_char
#    Returns one character of the current string. Due to the nature of the
#    ansi functions, this will only return characters not in ansi character
#    strings. While this is silly to use a function to do this, this helps
#    abstract the data set for situations in which the ansi functions are
#    replaced by standard string functions.
#
sub ansi_char
{
   my ($data,$pos) = @_;

   return @{$$data{ch}}[$pos];
}




# balanced_split
#    Split apart a string but allow the string to have "",{},()s
#    that keep segments together... but only if they have a matching
#    pair. This version should be escape sequence friendly.
#
# types:
#    1 : function split?
#    2 : split until end of function?
#    3 : split at delim
#    4 : split until delim, delim not included in result
#
#    FYI: Strings are split using ansi_substr() in as big of segments as
#         possible to avoid having extra escape sequences.
sub balanced_split
{
   my ($str,$delim,$type,$debug) = (ansi_init(shift),shift,shift,shift);
   my $end = ansi_length($str);
   my $stack = [];
   my $seg = [];
   my ($i,$start) = (0,0);
   my ($br,$bl,$pr,$pl) = ("{","}","(",")");                  # make vi happy

   for($i=0;$i < $end;$i++) {
      my $ch = ansi_char($str,$i);                           # get current ch

     # escaped character or escaped delim via % char but not %{varable}s
      if($ch eq "\\" ||
         ($ch eq "%" && ansi_substr($str,$i,undef,1) !~ /^%\{[a-zA-Z0-9]+\}/)) {
         $i++;
      } elsif($ch eq $pr) {                                # go down one level
         push(@$stack,{ ch => $pl, i => $i, start => $start, seg => $#$seg});
      } elsif($ch eq $br) {                                # go down one level
         push(@$stack,{ ch => $bl, i => $i, start => $start, seg => $#$seg});
      } elsif($ch eq $pl) {                                # go up one level?
         if($#$stack == -1) {                # end of function at right depth
            if($type <= 2) {
               push(@$seg,ansi_substr($str,$start,$i-$start));
               $start = $i + 1;
               last;
            }
         } elsif($ch eq @{@$stack[-1]}{ch}) {
            pop(@$stack);                  # pair matched, move up one level
         }
      } elsif($#$stack >= 0 && $ch eq @{@$stack[-1]}{ch}) {
         pop(@$stack);                      # pair matched, move up one level
      } elsif($ch eq $delim && $#$stack == -1) {      # delim at right level
         push(@$seg,ansi_substr($str,$start,$i-$start));
         return $$seg[0], ansi_substr($str,$i+1), 1 if($type == 4);
         $start = $i+1;
      }
      
      # at end of string and something is still in the stack, lets try going
      # back one at a time and see if it eventually parses out.
      if($i + 1 == $end && $#$stack >= 0) {
         my $rp = pop(@$stack);
         $i = $$rp{i};
         $start = $$rp{start};
         delete @$seg[($$rp{seg}+1) .. $#$seg] if($#$seg > $$rp{seg});
      }
   }

   if($type == 4) {                         # handle the various return types
      return ansi_string($str), undef, 0;
   } elsif($type == 3) {
      push(@$seg,ansi_substr($str,$start,$end-$start));
      return @$seg;
   } else {
      if($#$stack != -1) {
         return undef;
      } else {
         unshift(@$seg,ansi_substr($str,$start,$end-$start));
         return @$seg;
      }
   }
}


#
# d
#   Quick function to take a depth value and print out a coresponding
#   number of spaces. Optionally, print out some text afterwards.
#
sub d
{
   my ($depth,$fmt,@args) = @_;

   return sprintf("%*s%s",$depth,"",$fmt) if($#args == -1 && $fmt =~ /%/);
   return sprintf("%*s$fmt",$depth,"",@args);
}

#
# ltrim
#    Remove any leading spaces from the specified string.
#
sub ltrim
{
   my $txt = shift;
   $txt =~ s/^ +//;
   return $txt;
}

#
# fmt_equal
#    
sub fmt_equal
{
   my ($depth,$cmd,$rest) = @_;
   my ($out,$fmt,$space);

   my ($first,$second) = balanced_split($rest,"=",4);

   if($first =~ /^(\s+)/) {                             # preserve spaces?
      $space = $1;
      $first = $';
   } 

   if($second ne undef) {                            # split at equal sign
     my $fun = expand_function($depth+3,$first);

     if($fun =~ /\n/) {
        $fmt = "%s%s\n%s=\n";
     } else {
        $fmt = "%s%s%s=\n";
        $fun = $first;
     }
     $out .= d($depth,
               $fmt,
               $cmd,
               $space,
               $fun
              );
     $out .= d($depth+3,"%s",ltrim(expand_function($depth+3,$second)));
   } else {                                                # no equal sign
     $out .= d($depth,
               "%s%s%s",
               $cmd,
               $space,
               ltrim(expand_function($depth,$first))
              );
   }
   return $out;
}

#
# fmt_default
#   If there isn't a specalized rule to print out a segement of code,
#   default to using this way. The general idea will probably be to just
#   wrap() the text.
#
sub fmt_default
{
   my ($depth,$cmd,$rest) = @_;
   my $txt = $cmd .  $rest;

   if(length($txt) + $depth < $max) {          # small, don't need to touch
      return d($depth,"%s",$txt);
   } elsif($txt =~ /^\s*{(.*)}\s*$/) {        # handle text inside brackets
      my $out .= d($depth) . "{" .  ltrim(expand_code($depth+1,$1)) . "\n";
      $out .= d($depth) . "}";
      return $out;
   } else {                                  # free form text, just wrap it
      my $out;
      for my $line ( balanced_split($txt,";",3) ) { # split data at semi-colon
         $out .= expand_function($depth+3,$line) ;
      }
      return d($depth,ltrim($out));
   }
}

#
# fmt_while
#    Teenymush supports a @while command, format it accordingly.
#
#    Output Format:
#
#       @while ( <test condition> ) {
#          < code >
#       }
#
sub fmt_while
{
   my ($depth,$cmd,$rest) = @_;
   my $out;

   # look for while (<test condition>) { <code> };
   if($rest =~ /^\s*\(\s*(.*?)\s*\)\s*{\s*(.*?)\s*}\s*(;{0,1})\s*$/s) {
      $out .= d($depth,"%s","$cmd ( $1 ) {\n");
      $out .= expand_code($depth+3,$2) . "\n";
      $out .= d($depth,"%s","}");
      return $out;
   } else {                         # couldn't parse, fall back to default
      return fmt_default(@_);
   }
}


#
# fmt_switch
#   Handle formating of @switch/@select.
#
# Output Format
#    @select <text> =
#       <condition1>,
#          { <code>
#          }
#       <condition2>,
#          { <code>
#          }
#       DEFAULT,
#          { <code>
#          }
sub fmt_switch
{
   my ($depth,$cmd,$rest) = @_;
   my ($out,$space);

   my @list = balanced_split($rest,",",3);

   my ($first,$second) = balanced_split(shift(@list),"=",4);
   unshift(@list,$second);

   $out = d($depth,"%s",$cmd);
   
   if($first =~ /^(\s+)/) {
      $space = $1;
      $first = $';
   } 

   my $fun = expand_function($depth + length($cmd) + length($space),$first);
   if($fun =~ /\n/) {
      $out .= $space . ltrim($fun) . "=\n";
   } else {
      $out .= $space . $first . "=\n";
   }

   for my $i (0 .. $#list) {
      if($i == $#list) {
         add_spaces(\$out,\@list[$i]);
         $out .= expand_code($depth+3,@list[$i]);
      } elsif($i % 2 == 0) {
         add_spaces(\$out,\@list[$i]);
         $out .= d($depth+3) . @list[$i];
      } else {
         add_spaces(\$out,\@list[$i]);
         $out .= expand_code($depth+6,@list[$i]);
      }
      $out .= ",\n" if($i != $#list);
   }
   return $out;
}

#
# fmt_amper
#   The ampersand is used to set variables. Expand out the value
#   of the attribute and optionally put it on a new line.
#
sub fmt_amper
{
   my ($depth,$cmd,$rest) = @_;

   my ($first,$second) = balanced_split($rest,"=",4); 

   if($second eq undef) {
      return d($depth,
               "%s%s",
               $cmd,
               $first
              );
   } elsif(length($second) > 40) {
      return d($depth,
               "%s%s=\n%s",
               $cmd,
               $first,
               expand_function($depth+3,$second)
              );
   } else {
      return d($depth,
               "%s",
               $cmd . $first . "=" . ltrim(expand_function($depth+3,$second))
              );
   }
}

#
# fmt_dolist
#   @dolist is used to process fixed lists of data.
#
# Output Example:
#
#    @dolist <list>=
#    {
#       <code>
#    }
sub fmt_dolist
{
   my ($depth,$cmd,$rest) = @_;
   my ($ret1, $code, $ret2, $s1,$s2);

   # split into list and commands
   my ($first,$second) = balanced_split($rest,"=",4); 

   if($first =~ /^( +)/) {                # save leading spaces after @dolist
      $s1 = $1;
      $first = $';
   }
   if($second =~ /^( +)/) {               # save leading spaces after @dolist
      $s2 = $1;
      $second = $';
   }
   my $list = expand_function($depth+3,$first);

   if($second =~ /^\s*{/) {
      $code = expand_code($depth,$second);
   } else {
      $code = expand_code($depth+3,$second);
   }

   if($list =~ /\n/) {               # if list has returns, give it a new line
      $ret1 = "\n";
   } else {
      $list = $first;                          # fall back to original version
   }
   if($code =~ /\n/) {               # if code has returns, give it a new line
      $ret2 = "\n";
   } else {
      $code = $second;                         # fall back to original version
   }
   return d($depth,
            "%s%s%s%s=%s%s%s",
            $cmd,
            $s1,
            $ret1,
            $list,
            $s2,
            $ret2,
            $code
           );
}


#
# mywrap
#   Text::Wrapper gets close to what we want but needs a few tweaks
#   to get it all the way.
#
sub mywrap
{
   my ($depth,$txt) = @_;
   my $wrapper = Text::Wrapper->new(columns => $max - $depth, 
                                    body_start => d($depth+3),
                                    wrap_after => ", ");
   my $result = $wrapper->wrap($txt);
   $result =~ s/\n$//;                               # remove ending return
   return d($depth,"%s",$result);                  # indent + return results
}

#
# noswitch
#    Remove any switches at the end of a command and return the actual
#    command.
#
sub noswitch
{
   my $txt = shift;
 
   if($txt =~ /^([^\/]+)/) {
      return $1;
   } else {
      return $txt;
   }
}

#
# expand_code
#   Take the contents of an attribute and add spaces, returns, etc so
#   the code within is more readable.
#
sub expand_code
{
   my ($depth,$input,$indent) = @_;
   my ($out, $count);

   if($input =~ /^(\s*){(\s*)(.*?)}(\s*)$/) {              # handle code in {}s
      $out .= d($depth,"{$2") . "\n"; 
      $out .= expand_code($depth+3,$3,$indent);
      $out .= ret($out) . d($depth,"}");
      return $out;
   }
#   printf("\n\n");
   for my $txt ( balanced_split($input,";",3) ) {  # split data at semi-colon
#      printf("# '%s'\n",$txt);
#      next;
      ++$count;
      $depth = 3 if($indent && $count == 2 && $depth == 0);
      if($out ne undef) {                     # delims are eaten, add it back
         $out .= ";" if $out ne undef;
         $out .= "\n" if $txt !~ /^\s*$/;
      }
      if($txt =~ /^(\s*)([&"`:;\\])/ ||            # match single char cmd
         $txt =~ /^(\s*)([^ \\]+)/) {                 # match word command

         add_spaces(\$out,$1);
         if(defined @fmt_cmd{lc(noswitch($2))}) {    # specially formated cmd?
            $out .= &{@fmt_cmd{lc(noswitch($2))}}($depth,$2,$');
         } else {                                  # use default formating
            $out .= fmt_default($depth,$2,$');
         }
      }
   }

   return $out;
}

#
# compress
#    Take mushcode that has been "expanded" into multiple lines and
#    convert them back.
#
sub compress
{
   my $txt = shift;
   $txt =~ s/\r\s*|\n\s*//g;
   $txt =~ s/\r\s*|\n\s*//g;
   return $txt;
}

#
# file
#    Read a file and return the contents of the file.
#
sub file
{
   my $fn = shift;
   my (@data,$file);

   open($file,$fn) ||
     die("Could not open file '$fn' for reading.");

   for my $line (<$file>) {
      $line =~ s/\n//g;
      push(@data,$line);
   }
   close($file);

   return @data;
}

#
# err
#   Show an error
#
sub err
{
   my ($fmt,@args) = @_;
 
   printf(STDERR "Fatal Error:\n");
   printf(STDERR "   $fmt\n",@args);
   die();
}

#
# usage
#    provide the user some details about how to run this program.
#
sub usage
{
   my $out;

   $out = sprintf("\nUsage: $0 [<options>] <filename>\n\n");
   $out .= sprintf("   options:\n\n");
   for my $i (keys %valid) {
      $out .= sprintf("   --%-15s : %s\n",$i,@valid{$i});
   }
   return $out;
}

#
# handle_commandline
#   Parse the command line for any options that may be used.
#
sub handle_commandline
{
   for my $i (0 .. $#ARGV) {
      if(@ARGV[$i] =~ /^--([^ =]+)$/) {
         err("Bad arguement '$1' used\n".usage()) if !defined @valid{$1};
         @arg{$1} = 1;
      } elsif(@ARGV[$i] =~ /^--([^ =]+)=/) {
         err("Bad arguement '$1' used\n".usage()) if !defined @valid{$1};
         @arg{$1} = $';
      } elsif(@ARGV[$i] =~ /^-([^ =]+)$/) {
         for my $ch (split(//,$1)) {
            err("Bad arguement '$ch' used\n".usage()) if !defined @valid{$ch};
            @arg{$ch} = 1;
         }
      } elsif(!defined @arg{input}) {
         @arg{input} = @ARGV[$i];
      } else {
         err("Bad argument '@ARGV[$i]'.\n" . usage());
      }
   }
}

#
# noret
#   Remove a return from the end of the line
#
sub noret
{
   my $txt = shift;

   $txt =~ s/\n$//;
   return $txt;
}


#
# expand_args
#    Expand the arguements of a function. This is a helper function to
#    expand_function.
#
sub expand_args
{
   my ($level,$depth,$fun,$stack) = @_;
   my ($type,$alternate,$d,@new,$spaces);

   # add function name + ( and optional additional spacing
   $fun .= "(";
   my $offset = $depth + length($fun);

   $type = "]" if($fun =~ /^\s*\[/);                  # add closing bracket?

   $alternate = 1 if($fun =~ /switch/i);
     
   for my $i ( 0 .. $#$stack ) {                 # expand function arguements
      if($i == 0 || $i % 2 == 1) {
         $d = $offset;
      } elsif($alternate) {
         $d = $offset + 3;
      } else {
         $d = $offset;
      }

      # hackery to save spaces at the begining of function arguments.
      # and move them to the end of the previous line
      if(@$stack[$i] =~ /^(\s+)/) {
         (@new[$i],$spaces) = ($',$1);
         if($i != 0) {                  # can't add spaces yet in first pos
            @new[($i == 0) ? 0 : ($i - 1)] .= $spaces;
            $spaces = undef;
         }
      } else {
         @new[$i] = @$stack[$i];
      }

      my $fun = $spaces . ltrim(expand_function($d,@new[$i],$level+1));
      @new[$i] = d($d,"%s",$fun);

      @new[$i] .= "," if($i != $#$stack);
   }

   # don't show last function arguement if empty
   if($#new > 0 && ansi_remove(@new[$#new]) eq undef) {
      delete @new[$#new];
      @new[$#new] .= ",";
   }
  
   # put everything together and return
   return d($depth,"%s",$fun) .
          ltrim(join("\n",@new)) . "\n" . d($depth,")$type");
}

#
# pending
#    Text that look like function calls or bad function calls will break
#    up text segments into multiple peices if sent out the door right away.
#    Allow for joining these segments together and outputing in one segment
#    instead of multiple.
#
sub pending
{
   my $type = shift;

   if($type eq "add") {
      my ($data,$txt) = @_;
      $$data{txt} .= $txt;
   } elsif($type eq "out") {
      my ($data,$depth,$out,$txt) = @_;

      if($$data{txt} ne undef) {
         my $result = ret($out) . mywrap($depth,$$data{txt} . $txt);
         delete $$data{txt};
         return $result;
      }
   } else {
      die("pending: internal error, unknown '$type' type specified");
   }
}

sub ret
{
   return "\n" if(@_[0] ne undef && @_[0] !~ /\n\s*$/);
}

#
# expand function
#    Take a function or set of functions and make them more readable by
#    indenting and spreading across multiple lines.
#
# Prefered Format:
#
#    [function( arg1,
#               arg2,
#               arg3
#    )]
#
sub expand_function
{
   my ($depth,$txt,$level) = @_;
   my ($out, $space);
   my $pend = {};

   # expand most functions at least once, also but don't expand the small stuff
   if($depth + length($txt) < 75) { # && $level > 1) {
      return d($depth,"%s",$txt);
   }

   # unbracketed single function
   if($txt =~ /^\s*([a-zA-Z\_\!]+)\((.*)\)\s*$/) {
      my ($fun,$rest) = ($1,"$2)");
      my ($remainder,@stack) = balanced_split($rest,",",2);

      if(ansi_remove($remainder) =~ /^\s*$/) {
         return expand_args($level,$depth,$fun,\@stack);
      }
      return d($depth,"%s",$txt);                               # parse error
   }

   # process function by function
   while($txt =~ /\[([a-zA-Z\_\!]+)\(/) {               # possible function
      my ($fun,$before,$rest) = ($1,$`,$');

      # balance_split will split up args & find end of function
      my ($remainder,@stack) = balanced_split($rest,",",2);

      # throw any text found before the function into pending
      pending("add",$pend,$before,$out) if($before !~ /^\s*$/);

      # determine success by checking remainder
      if($remainder =~ /](\s*)/) {
         ($txt,$space) = ($',$1);

         if(ansi_remove($`) !~ /^\s*$/) {      # parse error / treat like text
            pending("add",$pend,"[$fun(");
            $txt = $rest;
         } else {                                           # valid function?
            my $res = expand_args($level,$depth,"[$fun",\@stack) .
                      $space;

            # don't expand single line and/or shorter functions
            $out .= ret($out);
            $out .= pending("out",$pend,$depth,$out);

            if($res !~ /\n/ || length($res) < 70) {    # funct small no expand
               $out .= ret($out) . 
                       d($depth,"[$fun(" . join(",",@stack) . ")]$space");
            } else {                                     # add expanded output
               $out .= ret($out) . $res;
            }
         }
      } else {                                # parse error / treat like text
         pending("add",$pend,"[$fun(",$out);
         $txt = $rest;
      }
   }

   if($txt ne undef || defined $$pend{txt}) {
      $out .= ret($out,$pend,$txt);
   }

   pending("add",$pend,$txt);
   $out .= pending("out",$pend,$depth);

   return $out;
#   return "<1>" . ret($out) . "<2>" . $out;
}

#
# simulate_command_completion
#   Instead of searching for the closest match on every command, populate
#   the hashtable with duplicate shorter version to allow one check hits.
#
sub simulate_command_completion
{
   for my $key (sort {length($a) <=> length($b)} keys %fmt_cmd) {
      for my $i (0 .. length($key)) {
         if(!defined @fmt_cmd{substr($key,0,$i)}) {
            @fmt_cmd{substr($key,0,$i)} = @fmt_cmd{$key};
         }
      }
   }
}

#
# add_spaces
#   Spaces are never significant at the begining of a line. This function
#   will slurp up spaces from the begining of a line and move them to the
#   end of the previous line. More then likely these spaces could be
#   dropped but it makes diffing the output easier and helps prove that
#   the code is not deleting things it shouldn't.
sub add_spaces
{
   my ($out,$str) = @_;

   if(ref($str) eq "SCALAR") {          # reference to input string passed in
      if($$str =~ /^(\s+)/) {
         $$str = $';                                  # fix up current string
         $$out = noret($$out) . $1 . "\n";                    # fix up output
      }
   } elsif($str =~ /^(\s+)/) {
      # actual string passed in, any changes would be lost and probably can't
      # be done anyways... so just modify the output which needs to always
      # be a reference to the string.
      $$out = noret($$out) . $1 . "\n";
   }
}

#
# expand_file
#   Take the contents of a file and pass them through expand_function /
#   expand_code to make the code hopefully more readable.
#
sub expand_file
{
  for my $line (file(@arg{input})) {
     $line =~ s/\r|\n//g;
  
     if($line =~ /^@@\s+mushify\s*$/) {
        printf("%s\n",$line);
        @arg{mushify} = 1;
     } elsif(@arg{mushify}) {
        delete @arg{mushify};
        if($line =~ /^\s*(&|@)([a-zA-Z0-9\_\!\+]+) ([^=]+)=/) {
           printf("%s%s %s=\n",$1,$2,$3);
           $line = $';
        }
        $line =~ s/%r/\n/g;
        $line =~ s/%b/ /g;
        $line =~ s/\[chr\(92\)\]/\\/g;
        while($line =~ /\[space\((\d+)\)\]/) {
           $line = $` . (" " x $1) . $';
        }
        while($line =~ /\[repeat\(([^,]+),(\d+)\)\]/) {
           $line = $` . ($1 x $2) . $';
        }
        printf("%s\n",$line);
     } elsif(length($line) < 60) {
        printf("%s\n",$line);
     } elsif($line =~ /^\s*([^ \/]+)/ && defined @fmt_cmd{lc($1)}) {
        my $out = expand_code(0,$line,1);
        printf("%s%s",$out,ret($out));
     } elsif($line =~ /^\s*(&|@)([a-zA-Z0-9\_\!\+]+) ([^=]+)=(\s*)(\[{0,1})/) {
        my ($type,$one,$two,$three,$four,$rest) = ($1,$2,$3,$4,$5,$');
        printf("%s%s %s=",$type,$one,$two);
        if($four eq "[") {                                  # bracketed function
           printf("\n%s\n",expand_function(3,"$four$rest"));
        } elsif($rest =~ /^\s*([a-zA-Z\_]+)\((.*)\)\s*$/) {    # non-bracketed
           printf("\n%s\n",expand_function(3,"$four$rest"));
        } elsif($rest =~ /^\s*(\$|\^)/) {
           my ($first,$second) = balanced_split("$four$rest",":",4);
           printf("%s:\n%s\n",$first,expand_code(3,$second));
        } else {                                              # txt or code?
           printf("\n%s\n",expand_code(3,"$four$rest")); # here
        }
     } elsif(($line =~ /^\s*@/ && substr($',0,1) ne "@") ||
           ($line =~ /^\s*([^ \/]+)/ && defined @fmt_cmd{lc($1)})) {
        my $out = expand_code(0,$line,1);
        printf("%s%s",$out,ret($out));
     } else {
        printf("%s\n",$line);
     }
  }
}

#
# mush
#   Convert the a string into its mush equivalent. $flag tells the function
#   if the code is going to be used inside a function.
#
# note:
#
#    \ ,     These characters are converted to chr() equalivalent because
#            not all mushes let you escape or {} these characters in the
#            same way when inside ansi() or functions.
#
sub tomush
{
   my ($txt,$flag,$start,$end) = @_;
   my ($i,$out,$output);

   for($i = 0;$i < length($txt);$i++) {                    # cycle each char
      my $ch = substr($txt,$i,1);
      if($ch eq " " && ($i + $start == 0 || ($i + 1 == length($txt) && $flag)||
         $i + $start + 1 == $end && !$flag)) {
         $out = "%b";                                 # special case spaces
      } elsif($ch eq " ") {
         $out = ($out eq " ") ? "%b" : " ";                 # alternate %bs
      } elsif($ch eq "\n") {
         $out = "%r";
      } elsif($ch eq "\\") {
         $out = "[chr(92)]";
      } elsif($ch eq '[' || $ch eq ']' || $ch eq '%' || $ch eq '\\' ||
         $ch eq '{' || $ch eq '}' || ($ch eq "," && $flag)) { # escape char
         $out = "\\$ch";
      } elsif($ch eq ",") {
         $out = "[chr(44)]";
      } else {
         $out = $ch;                                          # normal char
      }
      $output .= $out;                                      # add to output
   }
   return $output;
}

#
# mushify
#    Convert a string into its mush equivalent while trying to use as
#    few characters as possible. Do character compression using the
#    repeat() command.
#
sub mushify
{
   my $txt = shift;
   my ($ch,$done,$start,$i,$mult,$mush,$out,$loc);

   $txt =~ s/\t/     /g;                                      # expand tabs
   $txt =~ s/^\n{2,999}/\n/g;
   for($loc=0,$done=0;$loc <= length($txt);$loc++,$done=0) {
      for($i=1;$i < 10 && $i < (length($txt)- $loc) / 2 && !$done;$i++) {
         my $seg = substr($txt,$loc,$i);
         for($mult=1;$seg eq substr($txt,$loc + ($i*$mult),$i);$mult++) {};
         if(($seg eq " " && $mult > 6) || ((length($mush=tomush($seg,1,0,
            length($txt)))+length($mult) + 11) < (length($seg)*$mult))) {
            $out .= tomush(substr($txt,$start,$loc-$start),0,$loc,length($txt));
            $out .= ($seg eq " ") ? "[space($mult)]" : "[repeat($mush,$mult)]";
            $loc += length($seg) * $mult - 1;                  # skip chars
            $done = 1;                                    # get out of loop
         }
      }
      $start = $loc + 1 if($done);              # set next starting point
   }
   return $out . tomush(substr($txt,$start,length($txt)),0,$start,length($txt));
}



sub compress_file
{
   my $buf;

   for my $line (file(@arg{input})) {
      if($line =~ /^@@\s+mushify\s*$/) {
         printf("%s\n",ansi_remove(compress($buf))) if $buf ne undef;
         printf("%s\n",$line);
         $buf = undef;
         @arg{mushify} = 1;
      } elsif(@arg{mushify} && $line =~ /^(&|@)([a-zA-Z0-9\_\!\+]+) ([^=]+)=/) {
         printf("%s\n",mushify(noret($buf))) if $buf ne undef;
         $buf = $line;
      } elsif($line =~ /^@@\s+mushify off\s*$/) {
         printf("%s\n",mushify(noret($buf))) if $buf ne undef;
         printf("%s\n",$line);
         delete @arg{mushify};
         $buf = undef;
      } elsif(@arg{mushify}) {
         $line =~ s/\s+$//;
         $buf .= $line . "\n";
      } elsif($line =~ /^\s+/) {
         $buf .= $line . "\n";
      } elsif(@arg{mushify}) {
         $buf .= $line;
      } else {
         printf("%s\n",ansi_remove(compress($buf))) if $buf ne undef;
         $buf = $line . "\n";
      }
   }

   if(@arg{mushify}) {
     printf("%s\n",mushify($buf));
   } else {
     printf("%s\n",ansi_remove(compress($buf))) if $buf ne undef;
   }
}

# -------------------------------------------------------------------------- #
# main                                                                       #
# -------------------------------------------------------------------------- #

handle_commandline();
simulate_command_completion();

if(@arg{one}) {
   my $input = "\n" . join("",<STDIN>);      # remove return at end of input
   $input =~ s/[\r|\n]+$//;

   printf("%s\n",mushify($input));
} elsif(@arg{multi}) {
   for my $line (<STDIN>) {
      $line =~ s/\r|\n//g;
      printf("%s\n",mushify($line));
   }
} elsif(@arg{format}) {
   expand_file();
} elsif(@arg{unformat}) {
   compress_file();
} else {
   printf("%s\n",usage());
   exit();
}
