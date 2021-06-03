/loaded idler.tf

/set idler_author=Christian J. Robinson - heptite@gmail.com
/set idler_info=TinyFugue no-idle script.
/set idler_url=
/set idler_version=1.0.0

/require helplist.tf

/help_add /help_idler keeps you connected when idle

/def -i help_idler=\
     /echo -aB Idler help:%;\
     /echo /idler              Turns on the idler to send @@ to every 30 seconds%;\
     /echo /noidle             Turns off the idle loop

/eval /set idlerpid $[idlerpid ? : -1]

/def -i idler = \
  /if ({idlerpid} == -1) \
    /_idler %; \
    /echo %% No-Idle loop started. %; \
  /else \
    /echo %% No-Idle loop already running. %; \
  /endif

/def -i _idler = \
  /send -W @@ %;\
  /repeat  -0:00:30 1 /_idler %;\
  /set idlerpid %?

/def -i noidle = \
  /if ({idlerpid} != -1) \
    /kill %idlerpid %; \
    /set idlerpid -1 %; \
    /echo %% No-Idle loop killed. %; \
  /else \
    /echo %% No-Idle loop not running. %; \
  /endif
