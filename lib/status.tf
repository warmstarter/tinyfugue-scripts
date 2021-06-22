;;;; Socket line counts on status line

/loaded status.tf

;/require -q activity_status.tf

;; vwstatus, ininilog, and kaispell also modify the status area
;; vwstatus and infinilog are line 1, kaispell is line 2

;; Default Status Line:
;; @more:8:Br :1 @world :1 @read:6 :1 @active:11 :1 @log:5 :1 @mail:6 :1 insert:6 :1 kbnum:4 :1 @clock:5
;; Status Lines in use:
;; vw_tabs :1 inflog:6 kbnum:4 @clock12
;; kaispell:- 

/status_rm @mail
/status_rm @read
/status_rm insert
/status_rm @world
/status_rm @active
/status_rm @more

/set status_attr Crgb035,Cbgrgb001
/set status_height=2
/set status_pad=

/status_edit @log:6
/status_edit @clock:12:Crgb035
