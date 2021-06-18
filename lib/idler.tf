/loaded idler.tf

/set idler_author=Gwen Morse - Christian J. Robinson - heptite@gmail.com
/set idler_info=TinyFugue no-idle script.
/set idler_url=
/set idler_version=2.0.0

/require helplist.tf

/help_add /help_idler keeps you connected when idle

/def -i help_idler=\
     /echo -aB Idler help:%;\
     /echo /idler              Turns on the idler to send @@ to every 30 seconds%;\
     /echo /noidle             Turns off the idle loop

/eval /set idlerpid $[idlerpid ? : -1]

/def -i noidle = \
  /if ({idlerpid} != -1) \
    /kill %idlerpid %; \
    /set idlerpid -1 %; \
    /echo %% No-Idle loop killed. %; \
  /else \
    /echo %% No-Idle loop not running. %; \
  /endif

/def -i idler = \
  /if ({idlerpid} == -1) \
    /_idler %; \
    /echo %% No-Idle loop started. %; \
  /else \
    /echo %% No-Idle loop already running. %; \
  /endif

/def -i _idler = \
  /let _worlds= %;\
  /let i=1 %;\
  /let _sockets=$(/listsockets -T'tiny.*' -s) %;\
  /let _line=$(/nth %{i} %{_sockets}) %;\
  /while (_line !~ "") \
    /let _worlds=%_worlds %_line %;\
    /test ++i %; \
    /let _line=$(/nth %{i} %{_sockets}) %;\
  /done %;\
  /for i 1 $(/length %{_worlds}) \
    /send -w\$(/nth \%{i} \%{_worlds}) @@ %;\
  /repeat  -0:00:30 1 /_idler %;\
  /set idlerpid %?
