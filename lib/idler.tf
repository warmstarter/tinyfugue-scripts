/loaded idler.tf

/set idler_author=Gwen Morse - Christian J. Robinson - heptite@gmail.com
/set idler_info=TinyFugue no-idle script.
/set idler_url=http://christianrobinson.name/programming/tf/
/set idler_version=3.0.0

/require helplist.tf

/help_add /help_idler Prevents idle timeout by periodically sending to all worlds

/def -i help_idler=\
     /echo -aB Idler help: %; \
     /echo idler sends @@ at periodic intervals to all worlds. %; \
     /echo /idler status %; \
     /echo /idler enable %; \
     /echo /idler disable

; Set the variable 'idler_backlist' with a | between each world name to
; exclude worlds from the idle trigger /send command.  Eg:
; /set idler_blacklist=foo|bar|baz

/eval /set idlerpid $[idlerpid ? : -1]

/def idler = \
        /if (%1 =~ "") \
                /idler_status %; \
        /elseif (%1 =~ "status") \
                /idler_status %; \
        /elseif (%1 =~ "enable") \
                /idler_enable %; \
        /elseif (%1 =~ "disable") \
		/idler_disable %; \
        /endif

/def -i idler_status = \
  /if ({idlerpid} != -1) \
    /echo %% idler loop is disabled. %; \
  /else \
    /echo %% idler loop is enabled. %; \
  /endif

/def -i idler_disable = \
  /if ({idlerpid} != -1) \
    /kill %idlerpid %; \
    /set idlerpid -1 %; \
    /echo %% idler loop was disabled. %; \
  /else \
    /echo %% idler loop is already disabled. %; \
  /endif

/def -i idler_enable = \
  /if ({idlerpid} == -1) \
    /_idler %; \
    /echo %% idler loop was enabled. %; \
  /else \
    /echo %% idler loop is already enabled. %; \
  /endif

/def -i _idler = \
  /let _worlds= %;\
  /let i=1 %;\
  /let _sockets=$(/listsockets -T'tiny.*' -s) %;\
  /let _line=$(/nth %{i} %{_sockets}) %;\
  /while (_line !~ "") \
    /if /eval /test '%_line' !/ '{%idler_blacklist}' %;\
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

/_idler
