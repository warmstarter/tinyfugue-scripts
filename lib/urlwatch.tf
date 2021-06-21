/loaded urlwatch.tf

/set urlwatch_author=Vash@AnimeMUCK
/set urlwatch_info=Grabs URLs from worlds and makes webpage
/set urlwatch_url=
/set urlwatch_version=1.0.0

/require helplist.tf

/help_add /help_urlwatch Grabs URLS from worlds and makes webpage

/def -i help_urlwatch = \
  /echo -aB urlwatch help:%;\
  /echo This needs a help write-up

;---------------------------------------------------------------------------
; URL Watcher v1.05 - By Vash@AnimeMUCK ( sizer@san.rr.com )
;   Distribute at will! Though I'd like to hear of improvements.
;
; This is formatted for 4-space tabs.
;
; This compensates for not being able to launch urls from TF. It will watch
; your worlds and write out an html file with urls it sees go by. Then you
; can point your browser at the file and launch the urls from there. Note that
; it puts the newest urls at the top.
;
; It's not very efficient or very pretty ( I don't know TF macro language,
; just used other macros as samples ) but It Works For Me (TM).
;
; ---------------------------------------------------------------------------
; -- INSTALL
; - Put this urlwatch.tf in your tf-lib directory, then in your .tfrc
;   file put a '/load urlwatch.tf'.
; - If you can't do that, put it in your home directory or somewhere,
;   then '/load ~/urlwatch.tf' (for example).
; - If you get complaints about 'whitespace following final '\', then
;   you have the wrong CR/LF settings for this file.
; ---------------------------------------------------------------------------
; -- VERSIONS
; - V 1.05 - Sep 12 '07 - More variable substitution hell
; - V 1.04 - Sep 11 '07 - The urltarget wasn't being added correctly after 1.03
; - V 1.03 - Sep 08 '07 - Add _urlhead, some extra quoting niceness
; - V 1.02 - Aug 24 '07 - Fix quoting issue with regmatch
; - V 1.01 - Aug 24 '07 - Add _urltitle, _urltarget, multiple urls per line
; - V 1.00 - Aug 23 '07 - Initial release
; ---------------------------------------------------------------------------
; -- CONFIGURATION

; This is the file which gets written and you need to view in your browser.
;  In Firefox, File -> Open File..., in IE,  File -> Open -> Browse
/eval /set _urlfile=${LOGDIR}/web/tfurls.html

; comment out this line if you don't want urls opening in a new window/tab
;/set _urltarget=target="_blank"

; Title for the browser title bar/tab title
/set _urltitle=TinyFugue URLs

; Define your own style sheet info here, note the \ after every line
/set _urlcss=\
td { padding: 0.5em 1em; } \
.type0 { background: #f0fff0; } \
.type1 { background: #f0f0ff; } \

; How many urls you want to save for the page
/set _urlmax=100

; How often you want the page to auto-reload, in seconds (or 0)
/set _urltime=900

; anything else you want before the table of urls
/eval /set _urlhead=[ <a href="javascript:window.location.reload()" class='reload'>reload page</a> ]

; ---------------------------------------------------------------------------

; We'll need this more than once
/set _urlpattern=(http|ftp|https)://\S+[0-9A-Za-z/]
;/set _urlpattern=(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)

; Create the trigger
/eval /def -mregexp -p9 -F -q -t%_urlpattern urlwatch = /urlw2 %PL %P0 %PR

; blank the initial urls
/for i 1 %{_urlmax} /set _url%{i}=

;
; Catch the urls and write the file
;
/def urlw2 = \
; move all the old ones down one step
	/for i 2 %{_urlmax} /test eval("/set _url$$[ _urlmax - i + 2 ]=%%%_url$$[ _urlmax - i + 1]")%; \
; process the line to get all the urls
	/let url=%;\
	/let foo=1%;\
	/while ( foo > 0 )\
		/let url=%url%{PL}<a href="%{P0}" %{_urltarget}>%{P0}</a>%;\
		/let remain=%PR%;\
		/test foo:=regmatch( {_urlpattern}, remain )%;\
		/done%;\
	/set _url1=<td>${world_name}</td><td>%url%remain</td>%; \
; write the file
	/test f:=tfopen( {_urlfile}, "w" )%; \
	/test tfflush( %f, "off" )%; \
	/test tfwrite( %f, "<head><title>%_urltitle</title>" )%; \
	/if ( %_urltime != 0 ) \
		/test tfwrite( %f, "<meta http-equiv='refresh' content='%{_urltime}' />" )%; /endif %; \
	/test tfwrite( %f, "<style type='text/css'>" )%; \
	/test tfwrite( %f, {_urlcss} )%; \
	/test tfwrite( %f, "</style>" )%; \
	/test tfwrite( %f, "</head><body>" )%; \
	/test tfwrite( %f, {_urlhead} )%; \
	/test tfwrite( %f, "<table>" )%; \
	/for i 1 {_urlmax} /test tfwrite( %f, "<tr class='type$$[ i/2*2 = i ]'>" ), \
		tfwrite( %f, %%%{_url%%i} ), \
		tfwrite( %f, "</tr>" )%; \
	/test tfwrite( %f, "</table></body>" )%; \
	/test tfclose( %f )
