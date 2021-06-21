/loaded teach.tf

/set teach_author=
/set teach_info=Sends unparsed tf messages to world
/set teach_url=
/set teach_version=1.0.0

/require helplist.tf

/help_add /help_teach Sends unpased tf messages to a world

/def -i help_teach = \
  /echo -aB teach help:%;\
  /echo This needs a help write-up

; It's basically a tf version of /teach to help teach
; other folks some fun points of tf!
;
/def teach= \
        /send -w${world_name} pose types into tf --> [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;

/def esend= \
        /send -w${world_name} th > [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;
