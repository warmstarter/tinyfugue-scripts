/loaded cg.tf

/set cg_author=
/set cg_info=Connects to a world based on prefix match
/set cg_url=https://github.com/Sketch/tinyfugue-scripts
/set cg_version=1.0.0

/require helplist.tf

/help_add /help_cg Connects to an open world

/def -i help_cg = \
  /echo -aB cg help:%;\
    /echo /cg <world>           Switch to first connect world matching prefix %;\
    /echo Adds a /cg command. '/cg foo' will attempt to switch to the first %;\
    /echo connected world that prefix-matches 'foo', or failing that, the %;\
    /echo first connected world with 'foo' anywhere in the name. If neither %;\
    /echo exists, it prints an error to that effect. %;\

/def -i cg=\
  /let mylist=$(/listsockets -s)%;\
  /if (regmatch(strcat("(?:^| )(\\Q",{1},"\\E)(?:$| )"), mylist)) \
    /fg %{1} %;\
  /else \
    /if (regmatch(strcat("(?:^| )(\\Q",{1},"\\E\\S*)(?:$| )"), mylist)) \
      /fg %{P1} %;\
    /else \
      /if (regmatch(strcat("(?:^| )(\\S+\\Q",{1},"\\E\\S*)(?:$| )"), mylist)) \
        /fg %{P1} %;\
      /else \
        /echo -A %% Not connected to any world matching %1 %;\
      /endif %;\
    /endif %;\
  /endif
