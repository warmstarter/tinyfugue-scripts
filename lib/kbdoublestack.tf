/loaded kbdoublestack.tf

/set kbdoublestack_author=Greg Millam (Walker@M*U*S*H, captdeaf@gmail.com, github.com/captdeaf)
/set kbdoublestack_info=Double keyboard stack
/set kbdoublestack_url=https://github.com/Sketch/tinyfugue-scripts
/set kbdoublestack_version=1.0.0

/require helplist.tf

/help_add /help_kbdoublestack Double keyboard stack

/def -i help_kbdoublestack = \
  /echo -aB kbdoublestack help:%;\
  /echo Double Keyboard stack %;\
  /echo   %;\
  /echo This is useful when you're in the middle of typing a long line, %;\
  /echo and want to execute another command without losing the current line, %;\
  /echo but then sometimes you want to look back at that line without losing %;\
  /echo your current line, or . . . etc. =)  %;\
  /echo   %;\
  /echo Press esc-down to push the current text (if any) onto the top stack, %;\
  /echo and pop one off the bottom stack, or an empty text entry if bototm %;\
  /echo stack is empty. %;\
  /echo  %;\
  /echo Press esc-up to push current text onto the bottom stack and pop one off the %;\
  /echo top stack, if it has anything in it, or an empty text entry if top stack %;\
  /echo is empty. %;\
  /echo  %;\
  /echo You can have any number of these stacks, they honor %{kbnum} - %;\
  /echo That is, <esc><num><esc><up or down> %;\

/def -i kb_push = \
    /let n=$[+kbnum]%; \
    /if (n < 0) \
	/echo -e %% %0: illegal stack number %n.%; \
	/return 0%; \
    /endif%; \
    /let _line=$(/recall -i 1)%;\
    /if ( _line !~ "" ) \
        /eval \
	    /set _kb_stack_%{n}_top=$$[_kb_stack_%{n}_top + 1]%%;\
	    /set _kb_stack_%{n}_%%{_kb_stack_%{n}_top}=%%{_line}%;\
    /endif%;\
    /dokey dline

/def -i kb_pop = \
    /let n=$[+kbnum]%; \
    /if /test %{n} >= 0 & _kb_stack_%{n}_top > 0%; /then \
        /dokey dline%;\
        /eval \
	    /@test input(_kb_stack_%{n}_%%{_kb_stack_%{n}_top})%%;\
	    /unset _kb_stack_%{n}_%%{_kb_stack_%{n}_top}%%;\
	    /set _kb_stack_%{n}_top=$$[_kb_stack_%{n}_top - 1]%;\
    /endif

/def -i kbd_push = \
    /let n=$[+kbnum]%; \
    /if (n < 0) \
	/echo -e %% %0: illegal stack number %n.%; \
	/return 0%; \
    /endif%; \
    /let _line=$(/recall -i 1)%;\
    /if ( _line !~ "" ) \
        /eval \
	    /set _kbd_stack_%{n}_top=$$[_kbd_stack_%{n}_top + 1]%%;\
	    /set _kbd_stack_%{n}_%%{_kbd_stack_%{n}_top}=%%{_line}%;\
    /endif%;\
    /dokey dline

/def -i kbd_pop = \
    /let n=$[+kbnum]%; \
    /if /test %{n} >= 0 & _kbd_stack_%{n}_top > 0%; /then \
        /dokey dline%;\
        /eval \
	    /@test input(_kbd_stack_%{n}_%%{_kbd_stack_%{n}_top})%%;\
	    /unset _kbd_stack_%{n}_%%{_kbd_stack_%{n}_top}%%;\
	    /set _kbd_stack_%{n}_top=$$[_kbd_stack_%{n}_top - 1]%;\
    /endif

;;; probably needs new defs here due to conflicts

/purge -i key_esc_down
/purge -i key_esc_up
/def -i key_esc_down = /kb_push %; /kbd_pop
/def -i key_esc_up = /kbd_push %; /kb_pop
