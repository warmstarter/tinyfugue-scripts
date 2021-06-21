/loaded gagidlemsg.tf

/set gagidlemsg_author=Christian J. Robinson heptite at gmail dot com
/set gagidlemsg_info=Gags repeat idle messages from a player
/set gagidlemsg_url=http://christianrobinson.name/programming/tf/
/set gagidlemsg_version=1.0.0

/require helplist.tf

/help_add /help_gagidlemsg Gags repeat idle messages from a player

/def -i help_gagidlemsg = \
  /echo -aB gagidlemsg help:%;\
  /echo Automatically gags repeated idle messages from a player.

/if ({GagIdleCount} =~ "") \
	/set GagIdleCount=3 %; \
/endif

/def -iFmregexp -t'^Idle message from ([^:]+): (.+)' gagidlemsg_trigger = \
	/if (world_info('type') !/ '{tiny.*}') \
		/return %; \
	/endif %; \
	/let _name=%P1 %; \
	/let _message=%P2 %; \
	/let _fullmessage=%P0 %; \
	/let _world=${world_name} %; \
	/let _newname= %; \
	/let _len=$[strlen({_name})] %; \
	/let i=0 %; \
	/while ({i} < {_len}) \
		/let _chr=$[substr({_name}, i, 1)] %; \
		/if (regmatch('[a-zA-Z0-9_]', {_chr})) \
			/let _newname=$[strcat({_newname}, {_chr})] %; \
		/else \
			/let _newname=$[strcat({_newname}, ascii({_chr}))] %; \
		/endif %; \
		/test ++i %; \
	/done %; \
	/if /test \{idlemsg_%{_world}_%{_newname}\} =~ {_message} %; \
	/then %; \
		/test ++idlemsg_%{_world}_%{_newname}_count %; \
		/if /test \{idlemsg_%{_world}_%{_newname}_count\} == {GagIdleCount} %; \
		/then %; \
			/if ($(/listdef gagidlemsg_%{_world}_%{_newname}) !~ "") \
				/undef gagidlemsg_%{_world}_%{_newname} %; \
			/endif %; \
			/def -ag -w%_world -msimple -t'$[escape("\'", {_fullmessage})]' gagidlemsg_%{_world}_%{_newname} %; \
		/endif %; \
	/else \
		/set idlemsg_%{_world}_%{_newname}=%_message %; \
		/set idlemsg_%{_world}_%{_newname}_count=1 %; \
	/endif
