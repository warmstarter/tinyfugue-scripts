/loaded uptime.tf

/set uptime_author=
/set uptime_info=Checks the uptime of tf
/set uptime_url=
/set uptime_version=1.1.0

/require helplist.tf

/help_add /help_uptime Checks the uptime of tf

/def -i help_uptime = \
  /echo -aB uptime help:%;\
  /echo This needs a help write-up

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; If you want to know how long your tf has been running stick the following 
;;; line someplace early in your .tfrc, and then stick the macro below anywhere you like. 
;;;
;;; FROM: http://oj.egbt.org/dmoore/tf/#hints

;; Set the tf startup time in .tfrc, only once.
/test tf_start_time := (tf_start_time | time())

/def uptime = \
    /let seconds=$[time() - tf_start_time] %;\
    /echo % Your tf has been running for \
      $[trunc(seconds/86400)] days $[mod(seconds/3600,24)] hours \
      $[mod(seconds/60,60)] mins $[mod(seconds,60)] secs.
