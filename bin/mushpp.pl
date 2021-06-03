#!/usr/bin/perl -w

##############################################################################
#
# mushpp  -  Process formatted MUSH/MUX code with comments, defines and
#            macros into something a MUSH/MUX can handle.
#
# Copyright 2003-2010  Christian J. Robinson <heptite@gmail.com>
#
# Ideas, but no code borrowed from
# Unformat.pl <http://adam.legendary.org/index.php/Unformat>
# Written by Adam Dray <adam@legendary.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 675 Mass
# Ave, Cambridge, MA 02139, USA.
#
# Or on the web:
#  HTML: <http://www.gnu.org/copyleft/gpl.html>
#  Text: <http://www.gnu.org/copyleft/gpl.txt>
#
##############################################################################
#
# FIXME / TODO:
#  - Even though it works, this parser sucks. I should learn how to write a
#    "real" one.
#
##############################################################################


use 5.006;
use strict;
use File::Basename;
use Getopt::Long;

sub readfile($);
sub add_macro($$$);
sub process_macros($);
sub substitute_macro($$);
sub error(;$$);
sub output(;$$);
sub usage($);

my (%macros, %files, %opts);
my $BASENAME = basename($0);
my $VERSION = (split(' ', '$Revision: 1.31 $'))[1] . ' BETA';
my $success = 1;

$opts{'q'} = 0;

{
  # Make GetOptions use the error function (in case the -o option was used
  # first):
  local $SIG{'__WARN__'} = \&error;

  Getopt::Long::config qw/bundling/;
  GetOptions(\%opts,
    'o|outputcommand=s',
    'f|finishmessage=s',
    'd|define:s%' => sub{
      if (!defined($_[1]))
      {
        warn "Option $_[0] requires an argument\n";
        usage(1);
      }
      exit 1 unless add_macro('#define ' . $_[1] . ' ' . ($_[2] ? $_[2] : 1), '', '')
    },
    'q|quiet'    => sub{++$opts{'q'}},
    'h|help'     => sub{usage(0);},
    'H|man'      => sub{exec("perldoc $0")},
    'v|version'  => sub{output "$BASENAME version $VERSION"; exit 0;},
  ) or usage(1);
}

if (scalar(@ARGV))
{
  foreach my $file (@ARGV)
  {
    $success = readfile($file) && $success;
  }
} else {
  $success = readfile('-') && $success;
}

if ($success)
{
  #output 'Uploaded.';
  output $opts{'f'} if defined $opts{'f'};
  exit 0;
} else {
  output 'Some errors/warnings occurred during processing.', 1;
  exit 2;
}

sub readfile($)
# Purpose:
#  Read a file, unformat it, and process it.  Output is printed when EOF or a
#  '-' line is reached.
# Arguments:
#  1 - String: The filename to be read.
# Return value:
#  0 if any errors were encountered, 1 otherwise.
{
  my $file = shift;
  my ($line, $what, $tmp, $directory);
  my $rval  = 1;
  my $depth = 0;
  my $text  = '';

  local *FILE;

  unless (open(FILE, $file))
  {
    error "Can't open file \"$file\": $!\n";
    return 0;
  }

  $file = $file eq '-' ? '(stdin)' : $file;

  if ($files{$file})
  {
    error "File \"$file\" already read.\n";
    close(FILE);
    return 0;
  } else {
    ++$files{$file};
  }

  $directory = dirname($file);

  LOOP: while (<FILE>)
  {
    chomp($line = $_);

    next LOOP if $line =~ /^$/;

    SWITCH: {
      $line =~ /^\s*#\s*ascii/i && do
        {
          my $this_line   = $line;
          my $this_linenr = $.;
          my $tmp;

          ASCII: while (<FILE>)
          {
            chomp($line = $_);
            last ASCII if $line =~ /^\s*#\s*endascii(?:\s.*)?/i;

            $line =~ s/([\\\{\}\(\)\[\]\%])/\\$1/go;
            $line =~ s/\t/\%t/go;
            $line =~ s/\ /\%b/go;
            $line =~ s/\r//go;
            $tmp  .= (defined($tmp) ? '%r' : '') . $line;
          }
          
          $rval = 0 unless add_macro($this_line . ' ' . $tmp, $file, $this_linenr);

          last SWITCH;
        };

      (($what, $tmp) = ($line =~ /^\s*#\s*(ifn?def)\s+(.*)\s*/i)) && do
        {
          ++$depth;

          if ($what eq 'ifdef')
          {
            last SWITCH if defined $macros{$tmp};
          } else {
            last SWITCH unless defined $macros{$tmp};
          }

          $tmp = 1;

          while(<FILE>)
          {
            chomp($line = $_);
            ++$tmp if $line =~ /^\s*#\s*ifdef\s+(?:.*)\s*/i;
            if ($line =~ /^\s*#\s*endif(?:\s+(?:.*)\s*)?/i)
            {
              --$tmp;
              --$depth;
            }
            last SWITCH if $tmp == 1 && $line =~ /^\s*#\s*else\s*/i;
            last SWITCH unless $tmp;
          }

          last SWITCH;
        };

      $line =~ /^\s*#\s*else\s*/i && do
        {
          if ($depth)
          {
            $tmp = $depth;
            while(<FILE>)
            {
              chomp($line = $_);
              ++$depth if $line =~ /^\s*#\s*ifdef\s+(?:.*)\s*/i;
              --$depth if $line =~ /^\s*#\s*endif(?:\s+(?:.*)\s*)?/i;
              last SWITCH if $depth == $tmp - 1;
            }
          } else {
            error "#else without #ifdef on line $. of file \"$file\": $line\n";
            $rval = 0;
          }

          last SWITCH;
        };

      $line =~ /^\s*#\s*endif(?:\s+(?:.*)\s*)?/i && do
        {
          if ($depth)
          {
            --$depth;
          } else {
            error "#endif without #ifdef on line $. of file \"$file\": $line\n";
            $rval = 0;
          }

          last SWITCH;
        };

      $line =~ /^\s*#\s*(eval_)?define/i && do
        {
          MULTIDEF: while ($line =~ m/\\$/)
          {
            $line =~ s/\\$//;
            chomp($tmp = <FILE>);
            last MULTIDEF if eof FILE;
            $tmp =~ s/^\s*//;
            $line .= $tmp;
          }

          $rval = 0 unless add_macro($line, $file, $.);

          last SWITCH;
        };
      
      (($tmp) = ($line =~ /^\s*#\s*include(?:\s+(.+?)?\s*)?$/i)) && do
        {
          unless ($tmp)
          {
            error "Bad include on line $. of file \"$file\": $line\n";
            $rval = 0;
            last SWITCH;
          }

          $tmp = "$directory/$tmp"
            if (! -e $tmp && -e "$directory/$tmp");
          $rval = 0 unless readfile($tmp);

          last SWITCH;
        };

      # Ignore comments (must start at the beginning of a line):
      $line =~ m/^#/ && do
        {
          last SWITCH;
        };
      
      # '-' or 'EOL' on a line alone ends ends the current MUSHcode line:
      $line =~ /^(?:-|EOL)\s*$/ && do
        {
          print process_macros($text) . "\n";
          $text = '';

          last SWITCH;
        };
      
      # Default:
      $line =~ s/^\s*//;
      #$line =~ s|/@@.*@@/||;
      $line =~ s|/@@.*?@@/||;
      $text .= $line;
    }
  }
  print process_macros($text) . "\n" if $text ne '';

  close(FILE);

  return $rval;
}

sub add_macro($$$)
# Purpose:
#  Add a define/macro to the table.
# Arguments:
#  1 - String:  The full macro line.
#  2 - String:  The filename where the macro was found.
#  3 - Integer: The line number where the macro was found.
# Return value:
#  0 if any errors were encountered, 1 otherwise.
{
  my $define = shift;
  my $file   = shift;
  my $linenr = shift;
  my ($name, $info, $body, $err, $def);
  my $rval = 1;

  if ($file eq '')
  {
    $err = '';
    $def = ': ' . (split(/^#define /, $define, 2))[1];
  } else {
    $err = " on line $linenr of file \"$file\"";
    $def = ": $define";
  }

  if (defined $define && $define =~ /#\s*define\s+[^(\s]+\s*\([\w, ]*?[^\w, )][\w, ]*?\)/)
  {
    error "Bad define$err--bad parameter syntax$def\n";
    return 0;
  } elsif (defined $define && $define =~ /#\s*define\s+[^(\s]+\s*\([^)]+$/)
  {
    error "Bad define$err--missing parenthesis$def\n";
    return 0;
  } elsif (defined $define && $define =~ /#\s*define\s+([^\W(]+)\s*(?:\((?:[^)]+)\))?\s*$/)
  {
    error "Bad define$err--missing body$def\n";
    return 0;
  } elsif (defined $define && $define =~ /#\s*define\s+([^\W(]+)\s*\(([^)]+)\)\s+(.+)$/)
  {
    $name = $1;
    $info = [ $file, $linenr, 'macro' ];
    $body = [ $3, split(/,\s*/, $2) ];
  } elsif (defined $define && $define =~ /#\s*(define|ascii)\s+([^\s]+)\s+(.+)$/)
  {
    $name = $2;
    $info = [ $file, $linenr, $1 ];
    $body = $3;
  } elsif (defined $define && $define =~ /#\s*eval_define\s+([^\s]+)\s+(.+)$/)
  {
    $name = $1;
    $info = [ $file, $linenr, 'eval_define' ];
    $body = process_macros($2);

    EVAL: {
      local $SIG{'__WARN__'} = sub{error $_[0], 2};
      $body = eval($body);

      if ($@)
      {
        error $@, 0;
        return 0;
      }
    }
  } else {
    $define =~ s/\s*(#\s*ascii)\s.*/$1/;
    error "Bad define" . $err . $def;
    return 0;
  }

  if (defined $macros{$name})
  {
    error "Macro \"$name\" redefined on line $linenr of file \"$file\".", 2;
    error "Previous definition on line $macros{$name}{info}[1] of file \"$macros{$name}{info}[0]\".", 2;
    $rval = 0;
  }

  $macros{$name}{'info'} = $info;
  $macros{$name}{'body'} = $body;

  return $rval;
}

sub process_macros($)
# Purpose:
#  Find and substitute definitions/macros on an unformatted line with their
#  defined values.
# Arguments:
#  1 - String: The line to be processed.
# Return value:
#  The line after it's been processed.
{
  my $text = shift;
  my ($i, $j, @defines, @macros, @ascii, $defines, $macros, $ascii, $match);
  my $tmp = '';

  foreach my $key (keys %macros)
  {
    #if (ref $macros{$key}{'body'})
    if ($macros{$key}{'info'}[2] eq 'macro')
    {
      push(@macros, $key);
    } elsif ($macros{$key}{'info'}[2] eq 'ascii')
    {
      push(@ascii, $key);
    } else {
      push(@defines, $key);
    }
  }

  $defines = '\Q' . join('\E|\Q', @defines) . '\E';
  $macros = '\Q' . join('\E|\Q', @macros) . '\E';
  $ascii = '\Q' . join('\E|\Q', @ascii) . '\E';

  $i = 0;
  while ($tmp ne $text)
  {
    $tmp = $text;
    eval '$text =~ s/\b(' . $defines . ')\b/$macros{$1}{body}/g; $match = $1;'
      if @defines;

    ++$i;
    if ($i > 100)
    {
      error "Too many recursions. Runaway macro? Last processed: $match\n", 1;
      exit 1;
    }

    $j = 0;
    while (@macros && eval '($match) = ($text =~ m/\b(' . $macros . ')\s*\(/)')
    {
      $text = substitute_macro($text, $match);

      ++$j;
      if ($j > 100)
      {
        error "Too many recursions. Runaway macro? Last processed: $match\n", 1;
        exit 1;
      }
    }
    # If any macros were actually processed, strip backslashes from escaped
    # "\" and "," characters:
    $text =~ s/\\([,\\])/$1/g if $j;
  }

  # Process ASCII defines here so they're not recursively examined:
  eval '$text =~ s/\b(' . $ascii . ')\b/$macros{$1}{body}/g' if @ascii;

  return $text;
}

sub substitute_macro($$)
# Purpose:
#  Substitute a macro on an unformatted line with its value.
# Arguments:
#  1 - String: The line to be processed.
#  2 - Macro:  Which macro to find and substitute.
# Return value:
#  The line after the first occurrence of the macro has been substituted.
{
  my ($text, $macro) = @_;
  my ($start, $i, $arg_index, $c, %args, $tmp, $paren);

  # Locate the start of the macro, and the opening parentheses in the line:
  return $text if $text !~ m/\b${macro}\s*(\()/;
  $start = $-[0];
  $i     = $-[1];

  $c = substr($text, $i, 1);
  
  $arg_index = $paren = 0; $tmp = '';

  # Find each argument passed to the macro, handling nested parentheses:
  LOOP: while(($c = substr($text, $i++, 1)) ne '')
  {
    if ($c eq '(')
    {
      ++$paren;
      $tmp .= $c if $paren > 1;
    } elsif ($c eq ')')
    {
      --$paren;
      unless ($paren)
      {
        local $SIG{'__WARN__'} = sub{1};
        $args{$macros{$macro}{'body'}[$arg_index + 1]} = $tmp;
        ++$arg_index;
        last LOOP;
      }
      $tmp .= $c;
    } elsif ($c eq '\\')
    {
      # Handle escaped commas and backslashes:
      if (substr($text, $i, 1) eq ',')
      {
        # Preserve the backslash; they're stripped later to allow macro
        # nesting:
        $tmp .= '\\,';
        ++$i;
      } elsif (substr($text, $i, 1) eq '\\')
      {
        # Preserve the backslash; they're stripped later to allow macro
        # nesting:
        $tmp .= '\\\\';
        ++$i;
      } else {
        $tmp .= $c;
      }
    } elsif ($c eq ',')
    {
      if ($paren == 1)
      {
        local $SIG{'__WARN__'} = sub{1};
        $args{$macros{$macro}{'body'}[$arg_index + 1]} = $tmp;
        $tmp = '';
        ++$arg_index;
        ++$i while (substr($text, $i, 1) =~ m/\s/);
      } else {
        $tmp .= $c;
      }
    } else {
      $tmp .= $c;
    }
  }

  unless ($c eq ')')
  {
    error "No closing parentheses for macro call: $macro\n", 1;
    exit 1;
  }

  if ($#{$macros{$macro}{'body'}} != $arg_index)
  {
    error "Expected $#{$macros{$macro}{body}} argument(s), got $arg_index for macro: $macro\n", 1;
    exit 1;
  }

  # Fill the macro's arguments with the supplied arguments:
  $tmp = '\Q' . join('\E|\Q', keys %args) . '\E';
  eval '($tmp = $macros{$macro}{"body"}[0] ) =~ s/\b(' . $tmp . ')\b/$args{$1}/g';

  # Replace the called macro in the line with the new value, and return it:
  return substr($text, 0, $start) . $tmp . substr($text, $i);
}

sub error(;$$)
# Purpose:
#  Create an error message and output it.
# Arguments:
#  1 - String, optional:  The error message.
#  2 - Integer, optional: 0 - error (default)
#                         1 - fatal error
#                         2 - warning
# Return value:
#  Nothing meaningful.
{
  my $message = shift;
  my $type    = shift;

  if (defined $type && $type != 0)
  {
    if ($type == 1)
    {
      $type = 'FATAL ERROR:';
    } elsif ($type == 2)
    {
      $type = 'WARNING:';
    }
  } else {
    $type = 'ERROR:';
  }

  chomp($message = $message || '<Unknown error>');

  $message =~ s/^/$type /mg;

  output $message, 1;
}

sub output(;$$)
# Purpose:
#  Create a status message and output it, prepending the output command if
#  necessary.
# Arguments:
#  1 - String, optional:  The message.
#  2 - Boolean, optional: The true value causes the message to be printed on
#                         STDERR, otherwise STDOUT is used.
# Return value:
#  Nothing meaningful.
{
  my $message = shift;
  my $err = shift;

  # Be nice if the user requested silent output:
  return if ($opts{'q'} && !$err || $opts{'q'} > 1);

  if ($message)
  {
    chomp($message);
  } else {
    $message = '<Unknown message>';
  }

  $message =~ s/^/$opts{o} /mg
    if defined($opts{'o'});

  if ($err)
  {
    print STDERR "$message\n";
  } else {
    print STDOUT "$message\n";
  }
}

sub usage($)
# Purpose:
#  Output a short help statement.
# Arguments:
#  1 - Integer: Zero causes output on STDOUT and a successful exit value,
#               otherwise STDERR is used and the value is used as the exit
#               value.
# Return value:
#  Nothing, it causes the script to exit.
{
  my $rval = shift;

  output "Usage: $BASENAME [options] [files]", $rval;
  output " Options:",                          $rval;
  output " -q, --quiet",                       $rval;
  output " -o, --outputcommand <command>",     $rval;
  output " -f, --finishmessage <message>",     $rval;
  output " -d, --define <macro>[=value]",      $rval;
  output " -v, --version",                     $rval;
  output " -h, --help",                        $rval;
  output " ",                                  $rval;
  output "For details, see: $BASENAME --man",  $rval;

  exit $rval;
}

=head1 NAME

mushpp - Unformat and process MUSH/MUX code.

=head1 SYNOPSIS

B<mushpp> [options] [files]

=head1 DESCRIPTION

I<Mushpp> is a Perl script to process formatted MUSH/MUX code with comments,
defines and macros into something a MUSH/MUX can handle.

=head1 OPTIONS

=over 4

=item B<-o> I<command>, B<--outputcommand>=I<command>

Prefix all status or warning messages with 'I<command>', e.g.:

 mushpp --outputcommand=/echo fnord.mush

=item B<-f> I<message>, B<--finishmessage>=I<message>

Print I<message> when processing is finished, e.g.:

 mushpp --finishmessage=Uploaded. fnord.mush

This message isn't printed at all if the quiet option is used, and is prefixed
by the outputcommand, if specified.

=item B<-d>, B<--define>=I<macro>[=I<value>]

This adds a macro with with the specified value, with a default value of "1".
This is useful for enabling C<#ifdef>-ed sections of files.  See L<"Defines"> and
L<"Conditionals"> below.

=item B<-q>, B<--quiet>

Quiet status messages such as the uploaded message.  Issue this option two or
more times to silence even error output.  (Be careful with this.)

=item B<-v>, B<--version>

Show the version and exit.

=item B<-h>, B<--help>

Show a short usage statement and exit.

=item B<-H>, B<--man>

Show this documentation.

=back

=head1 INPUT FILE FORMAT

The files processed by mushpp will be de-indented and newlines up to a line
containing only a '-' or 'EOL' will be compressed into one line.

Lines starting with C<#> are comments, except for some special cases.  No
leading white space is allowed. See L<"Preprocessor Directives"> below.

You can inline comments with C</@@ text @@/>, but they can't span lines like
C's C</* */> comments.

Example:

 &foo me=$foo *:
   @switch %0=bar,{ /@@ Correct 'password'. @@/
     @pemit me=Foo
   },{ /@@ Incorrect 'password'. @@/
     @pemit me=Huh?
   }
 -

 @pemit me=Don't forget that anybody can use the foo%b
           command if they're in the same location as%b
           you or in your inventory!
 -

When run through mushpp will look like:

 &foo me=$foo *:@switch %0=bar,{ @pemit me=Foo},{ @pemit me=Huh?}
 @pemit me=Don't forget that anybody can use the foo%bcommand if they're in the same location as%byou or in your inventory!

=head2 Preprocessor Directives

=head3 Defines

You can use C<#define> in a similar way to the C preprocessor.  Be aware macros
are case sensitive.  Leading white space is allowed. For example:

 #define FOO BAR
  # define   BAR   BAZ
 
 @pemit me=FOO
 -
 @pemit me=foo
 -

Will result in:

 @pemit me=BAZ
 @pemit me=foo

=head3 Macros

You can also define macros:

 #define PEM(BAR, BAZ) switch(isdbref(BAR),1,pemit(BAR,BAZ),0,pemit(*BAR,BAZ))
 
 think [PEM(me, fnord)]
 -
 think [PEM(
     #1234,
         fnord
         fnord
 )]
 -

Will result in:

 think [switch(isdbref(me),1,pemit(me,fnord),0,pemit(*me,fnord))]
 think [switch(isdbref(#1234),1,pemit(#1234,fnordfnord),0,pemit(*#1234,fnordfnord))]

You may have a macro that spans multiple lines if you use a backspace to
continue the line to the next line.  Leading whitespace from continued lines
is removed.  For example:

 #define LONGMACRO(_string_) This is a long macro \
                             that prints _string_.
 LONGMACRO(some random string)

Will result in:

 This is a long macro that prints some random string.

There is no check for a \\ type pattern at the end of a line, so you can't
"escape" the backslash at the end of a macro definition.

During macro substitution, there I<is> a special check for "\," strings, which
allows you to have a comma in a provided argument.  Doubled backslashes are
reduced to one backslash, thus allowing you to get a literal "\," string by
using "\\\,".  Any other backslashed character will result in a literal
backslash and that character.

=head3 ASCII defines

The special directive C<#ascii I<name> ... #endascii> will MUSH-escape the
block of text between C<#ascii> and C<#endascii> and assign it to the I<name>
definition.  For example:

 #ascii BUTTERFLY

  .-.   .-. 
 .   \o/   .
 `._  U  _.'
  .'  U  `.
  `--'U`--'

 #endascii

 BUTTERFLY

Will result in:

 %r%b.-.%b%b%b.-.%b%r.%b%b%b\\o/%b%b%b.%r`._%b%bU%b%b_.'%r%b.'%b%bU%b%b`.%r%b`--'U`--'%r

Note that there's a leading and trailing blank line in this example; if you
don't include them there will be no leading and trailing C<%r> on the output
whenever C<BUTTERFLY> is used, which may or may not be desired.

Also note that ASCII blocks are I<not> examined for other defines and macros.
They are processed and output as-is.

=head3 Evaluated defines

The special directive C<#eval_define> uses Perl to evaluate the definition and
put the result into the definition name, but you can not use this to create
macros.  Be careful with this, as there's no input sanity checking; the code
is procesed for macros then pased directly to the Perl interpreter.  Example:

 #eval_define FOO  0x1
 #eval_define BAR  0x2
 #eval_define BAZ  0x4
 #eval_define ALL  FOO | BAR | BAZ

 FOO BAR BAZ ALL

Will result in:

 1 2 4 7

=head3 Conditionals

You can use C<#ifdef>/C<#ifndef> ... [C<#else> ...] C<#endif> to conditionally
include sections in the processed output.  Conditionals can be nested within
each other.  Example:

 #define FOO 1
 
 #ifdef FOO
 foo is defined
 -
 #endif
 
 #ifndef BAR
 bar is not defined
 -
 #endif

 #ifdef BAZ
 baz is defined
 #else
 baz is not defined
 #endif

This will result in:

 foo is defined
 bar is not defined
 baz is not defined

Currently there are no C<#if>, C<#elif>, or C<#elifdef> directives.

=head3 Includes

You can use C<#include> to include another file for processing.  The file is
first looked for in the current directory, then in the directory the current
file being processed resides in.  For example, if "F<defines.mux>" contained:

 #define MYNAME Foo
 #define MYDBREF #1234

And you processed the following:

 #include defines.mux
 
 @pemit me=
  My name: MYNAME%r
  My dbref: MYDBREF
 -

This will result in:

 @pemit me=My name: Foo%rMy dbref: #1234

=head1 USE WITH TINYFUGUE

You can fairly easily use this within TinyFugue with the following macro:

 /def upload = /quote -dexec -0 !mushpp -o /echo %*

Then from within TinyFugue you can simply issue a command such as "C</upload
fnord.mux>" and F<fnord.mux> would be processed and sent to your current
(foreground) world.

A more complex TinyFugue macro that lets you either process data directly from
the TinyFugue input area or a file if a filename is provided as an argument:

 /if ( {TMPDIR} =~ "" ) \
   /setenv TMPDIR=/tmp %;\
 /endif

 /def -i mushpp = \
   /if ({#} >= 1) \
     /quote -dexec -0 !~/bin/mushpp -o /echo -f Uploaded. %* %; \
     /return %; \
   /endif %; \
   /let tmpfile=$[strcat({TMPDIR}, '/tf-tmp.', rand(10000, 99999))] %; \
   /let f=$[tfopen({tmpfile}, 'w')] %; \
   /if ({f} == -1) \
     /echo -e %% Unable to open %tmpfile for writing. %; \
     /return %; \
   /endif %; \
   /echo -e %% Entering pipe mode.  Type "." to end. %; \
   /let _line=%; \
   /while ((tfread(_line)) >= 0 & _line !/ ".") \
     /@test tfwrite({f}, strcat(_line, \n)) %; \
   /done %; \
   /test $[tfclose({f})] %; \
   /quote -dexec -S !~/bin/mushpp -o /echo %tmpfile %; \
   /quote -decho -S !/bin/rm %tmpfile

=head1 EXIT CODES

There are three standard exit codes:

=over

=item * 0 -- Indicates successful processing with no warnings or errors.

=item * 1 -- Indicates a fatal error occurred during processing, and
processing was terminated at that point.

=item * 2 -- Indicates an error or warning occurred during processing, but
processing was completed.

=back

=head1 BUGS

=over

=item * #defines can recurse

A limit exists but if the limit is reached
processing will stop, an error will be printed, and the script will exit
without further output.

=item * Sometimes the diagnostic messages aren't very helpful

Especially for recursing macros (the location of the macro being processed has
been lost at that point).

=back

If you spot any other serious bugs, please email the author (see below).

=head1 AUTHOR

Christian J. Robinson E<lt>L<heptite@gmail.com>E<gt>

=head1 COPYRIGHT

Copyright 2003-2010  Christian J. Robinson E<lt>L<heptite@gmail.com>E<gt>

Ideas, but no code borrowed from
Unformat.pl (L<http://adam.legendary.org/index.php/Unformat>)
written by Adam Dray E<lt>L<adam@legendary.org>E<gt>.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 675 Mass
Ave, Cambridge, MA 02139, USA.

Or on the web:

 HTML: http://www.gnu.org/copyleft/gpl.html
 Text: http://www.gnu.org/copyleft/gpl.txt

=cut

# vim:ts=2:sw=2:et:
