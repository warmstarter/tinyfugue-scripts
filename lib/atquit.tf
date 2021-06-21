/loaded atquit.tf

/set atquit_author=Antti Pietikainen - heidel@operamail.com
/set atquit_info=Do something just before you quit
/set atquit_url=
/set atquit_version=1.0.0

/require helplist.tf

/help_add /help_atquit Automatic actions to take at quit

/def -i help_atquit=\
	/echo -aB Help for 'at quit':%;\
	/echo /quit_list            Show what will be done at /quit%;\
	/echo /quit_add             Add something to 'at quit' list%;\
	/echo /quit_remove          Remove something from the list%;\
	/echo /quit_do              Do the list now (useful for e.g. autosaving stuff)%;\
	/echo /@quit                Quit without doing the list;%;\
        /echo   %;\
        /echo Do something just before quit  %;\
        /echo Very useful for saving variables %;\
	/echo   %;\
        /echo note: you can use this for autosaving, too! %;\
        /echo /repeat -0:5:0 1000000 /quit_do  %;\
        /echo that'll save the settings every five minutes during the next 9 and half years

/def -i quit_add=\
	/if (strstr(quit_todo_list,textencode({*})) == -1) \
		/test quit_todo_list := strcat(quit_todo_list," ",textencode({*}))%;\
	/endif

/def -i quit_remove=\
	/test quit_todo_list := replace({*},"", quit_todo_list)

/def -i quit_list=\
	/if ({#}==0) \
		/if (quit_todo_list !~ "") \
			/quit_show %{quit_todo_list}%;\
		/else \
			/echo -aB % No commands to be performed at quit%;\
		/endif%;\
	/else \
		/echo -aB % Commands to be performed at quit:%;\
		/while ({#}) \
			/echo -aCgreen - $[textdecode({1})]%;\
			/shift%;\
		/done%;\
	/endif

/def -i quit_do=\
	/while ({#}) \
		/eval /eval -s0 $[textdecode({1})]%;\
		/shift%;\
	/done

/def -ag -Fp4000 -1 -q -h"CONFLICT" temp_hide_conflict

/def -i quit=\
	/quit_do %{quit_todo_list}%;\
	/@quit %{*}

