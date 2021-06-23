/loaded note.tf

/set note_author=Tero Koskinen aka Gurb - tkoskine@students.cc.tut.fi
/set note_info=Command for taking notes to a file
/set note_url=
/set note_version=1.3.0

/require helplist.tf

/help_add /help_note Note taking and reading

/def -i help_note=\
     /echo -aB Note help: %; \
     /echo /note              Shows your curent notes %; \
     /echo /noteadd <text>    Adds a new note with <text> %; \
     /echo /notedel <#>       Deletes note <#>

/set notelist=
/set _linecount=
/eval /set notefile=%{TFDIR}/mynotes.tf

/test (handle:=tfopen({notefile},"r"))
/while (tfread(handle, _linecount) >= 0) \
	/eval /set notelist=$[strcat({notelist},"!",{_linecount})]%;\
	/eval /echo %{_linecount}%;\
/done
/test (tfclose(handle))

/def note=\
	/let a=$[strchr({notelist},"!")+1]%;\
	/let count=1%;\
	/while (strlen(substr({notelist},{a})) > 0) \
		/let b=$[{a}-1+strchr(substr({notelist},{a}),"!")]%;\
		/if (b-a == -2) \
			/echo $[strcat(count,"|",substr({notelist},{a}))]%;\
			/let b=$[strlen({notelist})]%;\
		/elseif (b-a > 0) \
			/let c=$[substr({notelist},{a},{b}-{a}+1)]%;\
			/echo $[strcat(count,"|",{c})]%;\
		/endif%;\
		/let a=$[{b}+2]%;\
		/let count=$[{count}+1]%;\
	/done

/def noteadd= \
        /echo Note added%;\
        /set notelist=$[strcat({notelist},"!",{*})]%;\
        /test fwrite({notefile},{*})

/def notedel= \
        /echo Note %{1} deleted%;\
	/let notelist2=%;\
        /let a=$[strchr({notelist},"!")+1]%;\
        /let count=1%;\
        /while (strlen(substr({notelist},{a})) > 0) \
                /let b=$[{a}-1+strchr(substr({notelist},{a}),"!")]%;\
                /if (b-a == -2) \
			/if (count != {1}) \
                        	/let notelist2=$[strcat(notelist2,"!",substr({notelist},{a}))]%;\
			/endif%;\
                       	/let b=$[strlen({notelist})]%;\
                /elseif (b-a > 0) \
			/if (count != {1}) \
                        	/let c=$[substr({notelist},{a},{b}-{a}+1)]%;\
                        	/let notelist2=$[strcat(notelist2,"!",{c})]%;\
			/endif%;\
                /endif%;\
                /let a=$[{b}+2]%;\
                /let count=$[{count}+1]%;\
        /done%;\
	/set notelist=$[{notelist2}]%;\
	/notesave


/def notesave=\
	/test (handle:=tfopen({notefile},"w"))%;\
        /let a=$[strchr({notelist},"!")+1]%;\
        /let count=1%;\
        /while (strlen(substr({notelist},{a})) > 0) \
                /let b=$[{a}-1+strchr(substr({notelist},{a}),"!")]%;\
                /if (b-a == -2) \
			/test (tfwrite(handle,substr({notelist},{a})))%;\
                        /let b=$[strlen({notelist})]%;\
                /elseif (b-a > 0) \
                        /let c=$[substr({notelist},{a},{b}-{a}+1)]%;\
			/test (tfwrite(handle,{c}))%;\
                /endif%;\
                /let a=$[{b}+2]%;\
                /let count=$[{count}+1]%;\
        /done%;\
	/test (tfclose(handle))
