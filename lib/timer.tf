/loaded timer.tf

/set timer_author=Marvin Batmud
/set timer_info=Sets or displays a timer
/set timer_url=https://github.com/sbaker48/marvtf/tree/master
/set timer_version=1.5.0

/require helplist.tf

/help_add /help_timer Sets or displays a timer

/def -i help_timer = \
  /echo -aB timer help:%;\
  /echo These commands can create multiple named <timer> or %; \
  /echo a single one without a name. %; \
  /echo %; \
  /echo /timer_start   <timer>    Starts a <timer> %; \
  /echo /timer_stop    <timer>    Stops and displays a <timer> %; \
  /echo /timer_display <timer>    Displays a <timer> without stopping it

/def -i timer_start = \
    /let name=%{1} %; \
    /eval /set timer_%{name}_start=$[time()] %; \
    /echo -aBCRed ## %{name}: Timer Started ##

/def -i timer_display = \
    /let name=%{1} %; \
    /let start= %; \
    /test start := {timer_%{name}_start} %; \
    /let end=$[time()]%;\
    /let seconds=$[time() - {start}] %; \
    /echo -aBCRed ## %{name}: Timer Stopped after \
      $[trunc(seconds/86400)] days $[mod(seconds/3600,24)] hours \
      $[mod(seconds/60,60)] mins $[mod(seconds,60)] secs. ##

/def -i timer_stop = \
    /timer_display %{1} %; \
    /unset timer_%{1}_start
