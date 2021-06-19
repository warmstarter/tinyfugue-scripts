;;;; Socket line counts on status line

/loaded status.tf

/require -q activity_status.tf

;; ininilog and kaispell also modify the status area

;; Default Status Line:
;; /set status_field_defaults=@more:8:Br :1 @world :1 @read:6 :1 @active:11 :1 @log:5 :1 @mail:6 :1 insert:6 :1 kbnum:4 :1 @clock:5
;; Primary Status Line:
;; /set status_fields=@more:8:rBCwhite :1 @world:12:Cblue :1 activity_status :1 inflog:6 :1 @clock:12:Cblue

/status_rm @log
/status_rm @mail
/status_rm @read
/status_rm insert
/status_rm kbnum

/set status_attr BCmagenta
/set status_height=3

/status_edit @more:8:BrCwhite
/status_edit @world:12:BCblue
/status_add -A"activity_status" @log:6
/status_edit @clock:12:BCblue
