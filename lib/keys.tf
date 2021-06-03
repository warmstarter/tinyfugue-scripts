/loaded keys.tf

/set keys_author=Neerth, Lusternia
/set keys_info=Show a list of a bunch of command-altering and -navigating commands
/set keys_url=
/set keys_version=1.0.0

/require helplist.tf

/help_add /help_keys to screen print useful key combinations

/def -i help_keys = \
  /echo -aB Think help:%;\
  /echo /keys                  prints useful key combinations to the screen

/def keys = \
    /echo -paCblue $[strrep("=",80)] %; \
    /echo -paCbrightmagenta @{BCbrightcyan}CTR+A@{n}  $[pad("cursor to beginning of line",-31)]  @{BCbrightcyan}CTR+E@{n}  cursor to end of line %; \
    /echo -paCbrightmagenta @{BCbrightcyan}ALT+B@{n}  $[pad("cursor back one word",-31)]  @{BCbrightcyan}ALT+F@{n}  cursor forward one word %; \
    /echo -paCbrightmagenta @{BCbrightcyan}ALT+=@{n}  $[pad("cursor to matching bracket",-31)]  @{BCbrightcyan}ALT+V@{n}  toggle insert/overwrite mode %; \
    /echo -paCblue $[strrep("=",80)] %; \
    /echo -paCbrightyellow @{BCbrightcyan}CTR+D@{n}  $[pad("delete character",-31)]  @{BCbrightcyan}CTR+T@{n}  transpose characters %; \
    /echo -paCbrightyellow @{BCbrightcyan}CTR+K@{n}  $[pad("delete to end of line",-31)]  @{BCbrightcyan}CTR+U@{n}  delete back to front of line %; \
    /echo -paCbrightyellow @{BCbrightcyan}CTR+W@{n}  $[pad("delete backward word",-31)]  @{BCbrightcyan}ALT+D@{n}  delete forward word %; \
    /echo -paCblue $[strrep("=",80)] %; \
    /echo -paCbrightmagenta @{BCbrightcyan}ALT+C@{n}  $[pad("capitalize next word",-31)]  @{BCbrightcyan}ALT+L@{n}  make next word all lowercase %; \
    /echo -paCbrightmagenta @{BCbrightcyan}ALT+U@{n}  $[pad("make next word all uppercase",-31)]  @{BCbrightcyan}ALT+.@{n}  input last word of previous line %; \
    /echo -paCbrightmagenta @{BCbrightcyan}ALT+S@{n}  $[pad("check spelling of current pose",-31)]  @{BCbrightcyan}ALT+E@{n}  escape characters in current pose %; \
    /echo -paCblue $[strrep("=",80)] %; \
    /echo -paCbrightyellow @{BCbrightcyan}CTR+R@{n}  $[pad("recall last use of buffer text",-31)]  @{BCbrightcyan}@{n}  %; \
    /echo -paCblue $[strrep("=",80)] %;


