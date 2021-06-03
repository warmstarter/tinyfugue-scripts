/loaded escaper.tf

/set escaper_author=Tiercel/JBB, batzel at cceb dot med dot upenn dot edu
/set escaper_info=Escapes out characters in current input buffer
/set escaper_url=
/set escaper_version=1.0.0

/require helplist.tf

/help_add /help_esc escape out typed code

/def -i -F help_esc =\
  /echo -aB Tiercel's Escaper help%;\
  /echo If you've typed a long line of code (or grabbed it with Fuguedit), %;\
  /echo you don't want to have to go through by hand to escape out all those %;\
  /echo characters MUSH will eat. Instead, with this loaded, just hit esc-e, %;\
  /echo and it escapes all the odd characters in the command line.

/def -ib'^[e' = /test kbgoto(kblen() + 1) %;\
  /grab $(/escape %%[]{}\ $[kbhead()])
