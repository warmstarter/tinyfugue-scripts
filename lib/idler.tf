/loaded idler.tf

/set idler_author=Gwen Morse - Christian J. Robinson - heptite@gmail.com
/set idler_info=TinyFugue no-idle script.
/set idler_url=
/set idler_version=2.5.0

; Set the variable 'Idler_Exclude_Worlds' with a | between each world name to
; exclude worlds from the idle trigger /send command.  Eg:
; /set Idler_Exclude_Worlds=foo|bar|baz

/require helplist.tf

/help_add /help_idler keeps you connected when idle

/def -i help_idler=\
     /echo -aB Idler help:%;\
     /echo /idler              Turns on the idler to send @@ to at periodic intervals%;\
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
    /if /eval /test '%_line' !/ '{%Idler_Exclude_Worlds}' %;\
    /then \
      /let _worlds=%_worlds %_line %;\
    /endif %; \
    /test ++i %; \
    /let _line=$(/nth %{i} %{_sockets}) %;\
  /done %;\
  /for i 1 $(/length %{_worlds}) \
    /send -w\$(/nth \%{i} \%{_worlds}) @@ %;\
  /repeat  -0:$[rand(5,15)]:$[rand(60)] 1 /_idler %;\
  /set idlerpid %?
