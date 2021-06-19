;;; Make pages, multipages, and whispers stand out
;;; Gwen: I like to make my pages/multipages/whispers that I send out hilighted
;;; also, not just the ones people send to me. To discriminate between them,
;;; I use the non-bold form of the color I use for the incoming communication
;;; of the same type. This mostly helps me visually seperate any remote
;;; conversation from action in my location.

;bold cyan color pages
/def -i -Fp2 -aBCcyan -t'* pages[,:] *' hl_page1
/def -i -Fp4 -aBCcyan -t'You sense that * is looking for you in *' hl_page2
/def -i -Fp4 -aBCcyan -t'From afar, *' hl_page3
/def -i -Fp2 -aCcyan -t'Long distance to *' hl_page4
/def -i -Fp2 -aCcyan -t'You paged *' hl_page5

;bold green multi-pages
/def -i -Fp3 -aBCgreen -t'* pages (*) *' hl_mpage1
/def -i -Fp5 -aBCgreen -mregexp -t"(multipages|multi-pages)" hl_mpage2
/def -i -Fp5 -aCgreen -mregexp -t"(multipage|multi-page)" hl_mpage3
/def -i -Fp6 -aBCgreen -t'(To: *)' hl_mpage4
/def -i -Fp4 -aCgreen -t'(To: *) Long Distance, *' hl_mpage5
/def -i -Fp5 -aCgreen -t'(To: *) * pages: *' hl_mpage6

;bold blue color whispers
/def -i -Fp2 -aBCblue -t'* whispers[,:] *' hl_whisper1
/def -i -Fp3 -aBCblue -t'You sense *' hl_whisper2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Full-line highlights (odds and ends)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;When someone triggers a character @adesc (bold magenta)
/def -Fp5 -aBCmagenta -t'* looked at *.' hl_adesc
/def -Fp5 -aBCmagenta -t'* is looking at *.' hl_adesc2

;<OOC> Code
/def -Fp4 -aBCyellow -t'(<OOC>|<<OOC>) *' hl_ooc

;+watch code
/def -i -Fp5 -aBCgreen -t'<Watch> *' hl_watch

;MUX 'game' messages
/def -i -Fp5 -F -aBCgreen -t'GAME:*' hl_watch2

;+finger pemits
/def -i -Fp5 -F -aBCgreen -t'* +fingered you.' hl_finger

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; "Partial" highlights of importance
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Channels
;Any '[ ]' or '>'
/def -i -Fp9 -P0BCred -F -t'\\[*\\]' tiny_sh1
/def -i -Fp8 -P0BCred -mregexp -F -t"^\\[.*\\]" tiny_sh2
/def -i -Fp8 -P0BCred -mregexp -F -t"^[A-Za-z0-9 _-]*>" tiny_sh3
/def -i -Fp7 -P0BCred -mregexp -F -t"^<.*> " tiny_sh4

; Warnings
/def -i -Fp3 -F -P1xBCred -t'(ALERT>)' par_alert
/def -i -Fp1 -P0BCred -F -t'^[^ ]+ >>' night_chan

; Table-talk conversation partially in white
/def -i -Fp7 -P0xBCwhite -t'^(At|In) (your|the) [^,:]*[,:]' par_place1
