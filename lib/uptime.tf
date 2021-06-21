/loaded uptime.tf

/set uptime_author=
/set uptime_info=Displays uptime for TinyFugue
/set uptime_url=http://oj.egbt.org/dmoore/tf/#hints
/set uptime_version=1.1.0

/require helplist.tf

/help_add /help_uptime Displays uptime for TinyFugue

/def -i help_uptime = \
  /echo -aB uptime help: %; \
  /echo /uptime        Displays uptime for TinyFugue

/test tf_start_time := (tf_start_time | time())

/def uptime = \
    /let seconds=$[time() - tf_start_time] %; \
    /echo % Your tf has been running for \
      $[trunc(seconds/86400)] days $[mod(seconds/3600,24)] hours \
      $[mod(seconds/60,60)] mins $[mod(seconds,60)] secs.
