/loaded cheecat.tf

/set cheecat_author=Cheetah@M*U*S*H
/set cheecat_info=Two variants on tf's /cat command
/set cheecat_url=https://github.com/Sketch/tinyfugue-scripts
/set cheecat_version=1.0.0

/require helplist.tf

/help_add /help_cheecat Sends large unformatted text to MUSH

/def -i help_cheecat=\
     /echo -aB Cheecat help:%;\
     /echo /newcat works like /cat, except instead of evaluating and then sending, %;\
     /echo it grabs the result to the input window for editing at your own leisure. %;\
     /echo %;\
     /echo /rcat works like /newcat, but the result is display-equivalent MUSHcode %;\
     /echo of what was pasted. It is not, however, very efficient so while it's %;\
     /echo suitable for snippets, larger amounts of text will quickly run into %;\
     /echo input buffer limits.

/def -i newcat = \
  /echo -e %% Entering cat mode.  Type "." to end.%; \
  /let _line=%; \
  /let _all=%; \
  /while ((tfread(_line) >= 0) & (_line !~ ".")) \
    /if (_line =/ "/quit") \
      /echo -e %% Type "." to end \
      /cat.%; \
    /endif%; \
    /@test _all := strcat(_all, (({1} =~ "%%" & _all !~ "") ? "%%;" : ""), _line)%; \
   /done%; \
   /grab %_all

/def -i rcat = \
  /echo -e %% Entering cat mode.  Type "." to end.%; \
  /let _line=%; \
  /let _all=%; \
  /while ((tfread(_line) >= 0) & (_line !~ ".")) \
    /if (_line =/ "/quit") \
      /echo -e %% Type "." to end \
      /cat.%; \
    /endif%; \
    /let _line=$[replace("%", "%%", {_line})] %; \
    /@test _all := strcat(_all, (({1} =~ "%%" & _all !~ "") ? "%%;" : ""), {_line}, "%%r")%; \
  /done%; \
  /grab $[replace( "[", "%[", replace( "\\", "\\\\", replace("{", "%{", replace(" ", "%b", {_all}))))]
