/loaded copyto.tf

/set cg_author=Walker@M*U*S*H
/set cg_info=Copies objects from one world to another
/set cg_url=https://github.com/Sketch/tinyfugue-scripts
/set cg_version=1.0.1

/require helplist.tf

/help_add /help_copyto Copies objects between worlds

/def -i help_copyto = \
  /echo -aB copyto help:%;\
    /echo /copyto <world> <dbref>      Copies and onbject between worlds %;\
    /echo This command is for moving code from one MUSH to another. %;\
    /echo <world> is the TF defined named of the world you wish to copy to. %;\
    /echo <dbref> is the dbref number of the object on the current world. %;\
    /echo ex: /copyto Liberation #123 %;\

/def copyto= /set copy_world=%{1}%; /set copy_what=%{2}%; \
	/set copy_from=${world_name}%; \
	/send -w%{copy_from} think TF: Beginning copy: %{copy_what} to %{copy_world} ... %; \
 	/send -w%{copy_from} @decompile/prefix %{copy_what}=TFCopy >\%b %; \
	/send -w%{copy_from} think TFCopy:Decompile Finished %;

/def -p50 -ag -mglob -t"TFCopy:Decompile Finished" = \
	/unset copy_world %;

/def -p100 -ag -mglob -t"TFCopy > *" fuguecopy = \
	/if (copy_world !~ "") /send -w%{copy_world} %-2%; /endif

