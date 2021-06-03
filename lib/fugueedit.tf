/loaded fugueedit.tf

/set fugueedit_author=Kareila@ChaoticMUX, van@TinyTim, Gwen Morse
/set fugueedit_info=Improved Fugue Edit command
/set fugueedit_url=
/set fugueedit_version=1.1.0

/require helplist.tf

/help_add /help_ed Fugue Edit command

/def -i help_ed=\
  /echo -aB Fugue Edit help:%;\
  /echo /ed <obj>/<attr>            Edits the given attribute on the given object.%;\
  /echo /ng <obj>                   Grabs the name of the given object for editing.%;\
  /echo /lock <obj>[/<type>]        Edits the given lock (default lock if no type given).

; edmarker can be anything you like - no spaces allowed.
/set edmarker=FugueEdit

/eval /def -p100 -ag -t'%{edmarker} > *' edtrig = /grab %%-2

/def ed = \
  /if (regmatch('/',{*})) \
    /let edobj %PL %; \
    /let edattr %PR %; \
    /def -n1 -t#* -q -ag tempedtrig = \
      @pemit me = switch(%%*, \
      #-1, I don't see that here., \
      #-2, I don't know which one you mean!, \
      %{edmarker} > &%{edattr} %{edobj} = \
      [get(%%*/%{edattr})]) %; \
    /send @pemit me = locate(me, %{edobj}, *) %; \
  /else /echo %% %{edmarker}: ed argument must be of form <obj>/<attr> %; \
  /endif
/def -h"send ed *" edhook = /ed %-1

/def ng = \
  /if (regmatch('/',{*})) \
    /echo %% %{edmarker}: ng argument must be a valid object name %; \
  /else \
    /def -n1 -t#* -q -ag tempngtrig = \
      @pemit me = switch(%%*, \
      #-1, I don't see that here., \
      #-2, I don't know which one you mean!, \
      %{edmarker} > @name %* = [translate(fullname(%%*))]) %; \
    /send @pemit me = locate(me, %*, *) %; \
  /endif
/def -h"send ng *" nghook = /ng %-1

/def lock = \
  /if (regmatch('/',{*})) \
    /let edobj %PL %; \
    /let edattr %PR %; \
    /def -n1 -t#* -q -ag templocktrig = \
      @pemit me = switch(%%*, \
      #-1, I don't see that here., \
      #-2, I don't know which one you mean!, \
      %{edmarker} > @lock/%{edattr} %{edobj} = \
      [lock(%%*/%{edattr})]) %; \
    /send @pemit me = locate(me, %{edobj}, *) %; \
  /else \
    /def -n1 -t#* -q -ag templocktrig = \
      @pemit me = switch(%%*, \
      #-1, I don't see that here., \
      #-2, I don't know which one you mean!, \
      %{edmarker} > @lock %* = [lock(%%*)]) %; \
    /send @pemit me = locate(me, %*, *) %; \
  /endif
/def -h"send lock *" lockhook = /lock %-1

