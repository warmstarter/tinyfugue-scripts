/loaded teach.tf

/set teach_author=Greg Millam Walker@M*U*S*H
/set teach_info=Sends un-evaluated tf messages to world
/set teach_url=https://github.com/Sketch/tinyfugue-scripts
/set teach_version=1.0.0

/require helplist.tf

/help_add /help_teach Sends un-evaluated tf messages to a world

/def -i help_teach = \
  /echo -aB teach help:%;\
  /echo /teach <text>      Sends un-evaluated text publicly to the current world %; \
  /echo /esend <text>      Sends un-evaluated text privately to the current world

/def teach= \
        /send -w${world_name} pose types into tf --> [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;

/def esend= \
        /send -w${world_name} th > [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;
