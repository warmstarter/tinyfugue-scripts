/loaded kaispell.tf

/set kaispell_author=Chris "Kai" Frederick - kaispell@neofin.net
/set kaispell_info=Kai's on-the-fly spell checker for buffer
/set kaispell_url=http://www.neofin.net/kaispell
/set kaispell_version=1.4.1

/require helplist.tf
/require status.tf

/help_add /help_kaispell Fix spelling errors in pose

/def -i help_kaispell=\
     /echo -aB Kaispell help:%;\
     /echo /kiaspell         Fix spellings errors in pose%;\
     /echo Description and usage%;\
     /echo  %;\
     /echo  This will spell check your input to TinyFugue on the fly.  Misspelled%;\
     /echo  words are displayed on the status line in visual mode.%;\
     /echo  %;\
     /echo  Alt-S will feed the input through ispell. This allows you to get%;\
     /echo  suggestions and make corrections, as well as add words to the dictionary.

;; Installation:
;;
;;   This depends on spell, ispell, and tempfile.  On Ubuntu and other
;;   Debian-based distos, install them like this:
;;   sudo apt-get install spell ispell debianutils
;;
;;   Once that's done, simply load this script like this:
;;   /load /home/kai/kaispell.tf
;;
;;   You may put this line in your .tfrc to always load this script.
;;
;; Known bugs:
;;
;;   The results bar will not play nicely with other scripts that use an
;;   extended status bar.
;;
;; Known lameness:
;;
;;   TF doesn't seem to have a sane way to feed STDIN of a process.  The best
;;   I can figure is using echo.  Rather than deal with shell escapes, I'm
;;   I'm putting the data in a temp file.  Write caching makes this fast
;;   enough that I don't notice any lag on my small VPS, even under disk load,
;;   but mounting /tmp sync will slow it down a bit.  Let me know if there's a
;;   better way!
;;
;;   This redraws the status bar a lot, which causes occasional cursor
;;   flickers.  It's probably terrible if you're on a modem, but life's
;;   already terrible if you're on a modem in this age.
;;
;; Version history:
;;   v0.01 - 2011.01.28 - Initial release to a few friends for testing
;;   v0.02 - 2011.01.29 - Multithreaded to prevent lag, prefs section,
;;                        separate results bar with autohide and scrolling.
;;   v0.03 - 2011.02.03 - Better error messages for missing programs, external
;;                        programs now in variables; results moved to right.
;;   v0.04 - 2011.02.04 - Add /kaispell_version and update checks
;;   v0.05 - 2011.02.06 - TinyFugue 4 compatible, changed update notifier
;;   	                  - .01 - All macros -i
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Copyright and Distribution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Copyright (c) 2011 by Chris "Kai" Frederick <kaispell@neofin;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Preferences
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 1 to display a separate results bar; 0 to squeeze it on the default one
; You'll need at least 90 columns for it to be useful on the default bar, or
; you'll want to trim some other things off.  This is forced off in TF4.
/set kaispell_resultsbar=1

; 1 to auto-hide the results bar; 0 to leave it open.  Forced off in TF4.
 /set kaispell_autohide=0

; How long (seconds) results stay on screen after hitting enter.  TF4
; requires an integer; TF5 allows decimals.
/set kaispell_linger=2

; Results display attributes. Default hCred = Highlighted Color RED.
/set kaispell_color=hCred

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Functions and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; input_tempfile
;; Put the current input line in a temp file, and then pass all arguments
;; to eval.  The eval will presumably use /sh, /quote !, or similar to
;; process the text.  It's up to the evaled code to remove the temp file.
/def -i input_tempfile = \
	/let tempfile=$(/quote -S -decho !%kaispell_cmd_tempfile) %; \
	/if (kaispell_tf4 ? tempfile =/ '/tmp/tf_*' : {?} == 0 ) \
		/let tempfh=$[tfopen(tempfile, 'w')] %; \
		/test tfwrite(tempfh, $$(/recall -i 1)) %; \
		/test tfclose(tempfh) %; \
		/eval %* %;\
	/else \
		/echo -e Unable to run "%kaispell_cmd_tempfile".  Error was: %tempfile %; \
	/endif

;; kaispell_fork
;; Fork a process to feed the input line through spell.  The list of
;; misspelled words (possibly an empty list provided by echo) is passed to
;; kaispell_callback.  This is called from keybindings or the callback. 
/def -i kaispell_fork = /input_tempfile /quote -0 -dexec \
	/kaispell_callback !%kaispell_cmd_spell

;; kaispell_callback
;; Update the status line with results.  If another run is queued, run it.
;; This is only thread safe if it runs synchronous.  as of tf5.08b, that
;; seems to be the case, but I don't know if it's a guarantee forever.  If
;; it ever changes, it will (very rarely) fork two processes at once, and
;; end up with kaispell_queue == -1.  The WTF will trigger, and everything
;; should be fine again.
/def -i kaispell_callback = \
	/let results=%* %; \
	/if (kaispell_autohide) \
		/if (strlen(results)) \
			/set status_height=2 %; \
		/else \
			/set status_height=1 %; \
		/endif %; \
	/endif %; \
	/if (strlen(results) > test(kaispell_width)) \
		/let results=...$[substr(results, 3-test(kaispell_width)) ] %; \
	/endif %; \
	/set kaispell_status=%results %; \
	/if (--kaispell_queue == 1) \
		/kaispell_fork %; \
	/endif

;; ispell
;; Feed the current input buffer through ispell for correction.
/def -i ispell = \
	/let shpauseold=%shpause %; \
	/set shpause=off %; \
	/input_tempfile \
		/set cmd=-q %kaispell_cmd_ispell %%; \
		/if (sh(cmd) == 0) \
			/let grab_buffer=$$(/quote -S -decho '%%tempfile) %%; \
			/test grab(grab_buffer) %%; \
		/else \
			/echo -e kaispell: Unable to run "%%cmd".  Is it installed and in your PATH? %%; \
		/endif %%; \
		/sys rm %%tempfile %; \
	/set shpause=%shpauseold %; \
	/kaispell_enqueue

;; kaispell_enqueue
;; Launch a spellcheck, or if one is already running, enqueue another run
;; with the updated input.
;; This is not thread safe (see kaispell_callback), but runs sync in 5.08b.
/def -i kaispell_enqueue = \
	/if (kaispell_queue == 0) \
		/set kaispell_queue=1 %; \
		/kaispell_fork %; \
	/elseif (kaispell_queue == 1) \
		/set kaispell_queue=2 %; \
	/elseif (kaispell_queue == 2) \
;; No op
	/else \
		/echo WTF, resetting spellcheck %; \
		/set kaispell_queue=0 %; \
	/endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Init Globals

/set oldslash=off
/set kaispell_cmd_ispell=ispell -x %tempfile
/set kaispell_cmd_spell=(echo;spell %tempfile;rm %tempfile)2>&1|fmt -w 2500|tail -n 1
/set kaispell_cmd_tempfile=tempfile -p tf_

; kaispell_queue can be:    and kaispell_enqueue will:
;   0 - not running         set it to 1 and start a process
;   1 - running             set it to 2, to queue another run
;   2 - running and queued  do nothing
/set kaispell_queue=0

; kaispell_status - the status bar display buffer
/set kaispell_status=

;; Set up the status line.

/if (kaispell_resultsbar) \
; create a new bar
  /eval /status_add -c -r1 kaispell_status:-:%kaispell_color '__' %; \
  /set kaispell_width=columns() - 7 %; \
/else \
; Squeeze it after world on the default bar.  World becomes fixed-width,
; and kaispell_status is the new variable-width field.
  /set kaispell_autohide=0 %; \
  /set statusbar_height=1 %; \
  /status_edit @world:10: %; \
  /eval /status_add -x -A@world kaispell_status::%kaispell_color %; \
  /set kaispell_width=columns() - 70 %; \
/endif

/if (kaispell_resultsbar & !kaispell_autohide) \
  /set status_height=3 %; \
/endif

;; Keybindings

; First, do all the easy ones.
; foreach (char c) at (index i) in kaispell_bindings { /def keybinding }
/set kaispell_bindings=~!@#^&*()_+`-[]{}|;<>?,./":
/for i 0 strlen(kaispell_bindings)-1 \
	/let c=$[substr(kaispell_bindings,i,1)] %; \
	/def -ib'%c' key_%c = /input %c %%; /kaispell_enqueue
/unset kaispell_bindings

; Now, all the things that have to be escaped:
/def -ib\'  key_quote      = /input \'%; /kaispell_enqueue
/def -ib\\  key_backslash  = /input \\%; /kaispell_enqueue
/def -ib\$  key_dollar     = /input \$%; /kaispell_enqueue
/def -ib\%  key_percent    = /input \%%; /kaispell_enqueue
/def -ib\=  key_equals     = /input \=%; /kaispell_enqueue
/def -ib' '  key_space     = /test input(' ') %; /kaispell_enqueue

; Clear the results a couple seconds after hitting enter
/def -ib'^M' key_enter     = /dokey newline %; /repeat -%kaispell_linger 1 /kaispell_enqueue

; Finally, Alt-S for ispell
/def -ib^[s = /ispell

