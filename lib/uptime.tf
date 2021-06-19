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
      $[seconds/86400] days $[mod(seconds/3600,24)] hours \
      $[mod(seconds/60,60)] mins $[mod(seconds,60)] secs.
