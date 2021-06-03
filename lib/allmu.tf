/loaded allmu.tf

/set allmu_author=
/set allmu_info=Sends a command to all open worlds
/set allmu_url=
/set allmu_version=2.0.0

/require helplist.tf

/help_add /help_allmu sends a command to all open worlds 

/def -i help_allmu = \
  /echo -aB allmu help:%;\
  /echo /allmu <command>           send <command> to all open worlds

/def allmu=\
  /send -W %{*}
