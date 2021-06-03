;; Check how many lines in a file via external command:
; /set numLines $(/wc -l myfile.txt)

;; Executing commands based on MUSH output.
;; Dangerous, but with some uses.
; https://tinyurl.com/y8b7wqhf

;; Highlight specific or arbitary names
; https://tinyurl.com/yb42ebbv
; https://tinyurl.com/ycnbuz3j

;; 'tabbed'
; https://tinyurl.com/y8gesa8w

;; columns, text formatting
; https://tinyurl.com/ybvwadjx

;; advanced quoting
; https://tinyurl.com/ya9yq8ux

;; timestampping
; https://tinyurl.com/ybpx6q4c

;; dummy world variant
; https://tinyurl.com/ybvoj3cg

;; status bar and evaluating MUSH info
; https://tinyurl.com/yj3b6k89

;; multi-line status
; https://tinyurl.com/yfoxzpk6

;; infinilog
; check out configs

;; kbdoublestack
; see if there's a way to see when you have something in your buffer or not

;; mushpp
; go through all the options in the bin directory

;; bind
; see what else there might be, add to keys

;; gag+hilite
; Add what's needed

;; Meta info
; script_<name>_<info> is there, check out kaispell to see what can be done with it.
; Script info ... reconsider naming scheme here, maybe drop the script_
; /echo -e -aCgreen kaispell> Version %kaispell_version

;; tfrc
; figure out nl
; figure out hostname
; figure out where to put shell
;;;
; add a changelog
; uses changes.tf from stdlib

;; note
; add a way to print a specific line
; add a way to pipe a specific line to the world
; this would be through a pipe and maybe picking the command before it
; a number on it's own breaks counting
; delete or add without a number indicates success and does nothing
; option to clear it all

;;; TODO
;;; Bind keys for isize
;;; General clean-up
;;; Help Docs
;;; commands in .tfrc if needed
;;; go over special variables
;;; Check out the nice prints in tiny.macros.organize.tf
;;; figure out why it's escape sometimes and alt other times
;;; Status prompt
;;; Variables
;;; aliases and maybe move things wholly into them

;;;KEYS
; Add all bindings to this
; Make sure they don't interfere with terminal/tmux bindings
; Separate programs that use bound keys versus don't
; Investigate bash and vi bindings
; Perhaps make multiple menus
; Perhaps separate actual bindings

;;;Config and Help
; break out config options and help options into .tfrc as an option
; help into a separate help file?

;;; atquit
; redo history files with atquit in mind, see what's still needed

;;; Cat and recall and such
; play around with making this work properly for quoting from logs
