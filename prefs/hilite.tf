; Pages
/def -i Fp2 -aBCcyan -mregexp -t'^(.+ pages:) .+' tiny.page1
/def -i Fp2 -aBCcyan -mregexp -t'^(From afar,) .+' tiny.page2
/def -i Fp2 -aBCcyan -mregexp -t'^(You paged,) .+' tiny.page3
/def -i Fp2 -aBCcyan -mregexp -t'^(Long distance to) .+' tiny.page4
/def -i Fp2 -aBCcyan -mregexp -t'^(To \(.+\), .+ pages:) .+' tiny.page5

; Page errors
/def -i Fp2 -aBCred -mregexp -t'^(I don\'t recognize .+)$' tiny.pageerr1
/def -i Fp2 -aBCred -mregexp -t'^(No one to page.)$' tiny.pageerr2
/def -i Fp2 -aBCred -mregexp -t'^(Sorry, .+ is not connected.)$' tiny.pageerr3

; General Errors
/def -i -Fp2 -aBCred -mregexp -t'^Huh\?.*' tiny.helperr
/def -i -Fp2 -aBCred -mregexp -t'^(Idle|Reject|Away) message from [A-Za-z ]*:' tiny.pageerr
/def -i -Fp2 -aBCred -mregexp -t'^I don\'t see that here\.' tiny.nothere
/def -i -Fp2 -aBCred -mregexp -t'^Permission denied.' tiny.noperm
/def -i -Fp2 -aBCred -mregexp -t'^No entry for \'.*\'.' tiny.nohelp
/def -i -Fp2 -aBCred -mregexp -t'^You can\'t go that way.' tiny.noway
/def -i -Fp2 -aBCred -mregexp -t'^Sorry.*' tiny.sorry
/def -i -Fp2 -aBCred -mregexp -t'^Invalid.*' tiny.invalid
/def -i -Fp2 -aBCred -mregexp -t'^Whisper to whom\?' tiny.whispererr

;bold blue color whispers
/def -i -Fp2 -aBCblue -mregexp -t'^* whispers[,:] *' hl_whisper1
/def -i -Fp2 -aBCblue -mregexp -t'^You sense *' hl_whisper2

;<OOC> Code
/def -i -Fp2 -aBCyellow mregexp -t'^(<OOC>|<<OOC>>) .+' hl_ooc

;;; "Partial" highlights of importance

;Channels
;Any '[ ]' or '>'
/def -i -Fp2 -P0BCblue -mregexp -t'^\\[*\\]' tiny_sh1
/def -i -Fp2 -P0BCblue -mregexp -t"^\\[.*\\]" tiny_sh2
/def -i -Fp2 -P0BCblue -mregexp -t"^[A-Za-z0-9 _-]*>" tiny_sh3

; Table-talk conversation partially in white
/def -i -Fp2 -P0xBCwhite -mregexp -t'^(At|In) (your|the) [^,:]*[,:]' par_place1

