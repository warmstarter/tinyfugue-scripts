/loaded connect.tf

/set connect_author=
/set connect_info=Connects to defined worlds
/set connect_url=https://github.com/Sketch/tinyfugue-scripts
/set connect_version=2.0.0

/require helplist.tf

/help_add /help_connect Connects to defined worlds

/def -i help_connect = \
  /echo -aB connect help:%;\
    /echo /ca                  Connects to all worlds %; \
    /echo /cc <world>          Connects to <world> %; \
    /echo /cg <world>          Switch to first connected world matching prefix

/def ca = /mapcar /connect $(/listworlds -s)

/def cc = /connect $[world_info()]

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
