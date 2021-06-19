/loaded helplist.tf

/set helplist_author=Antti Pietikinen - heidel at operamail dot com
/set helplist_info=Manages a list of help-commands for different modules
/set helplist_url=
/set helplist_version=1.0.0

/require textencode.tf

/def -i help_add=\
  /if (strstr(help_list,textencode({*})) == -1) \
    /test help_list := strcat(help_list," ",textencode({*}))%;\
  /endif

/def -i help-list=\
  /if ({#}==0) \
    /if (help_list !~ "") \
      /help-list %{help_list}%;\
    /else \
      /echo -aB % No help commands set%;\
    /endif%;\
  /else \
    /echo -aB % List of help commands:%;\
    /while ({#}) \
      /let help_string=$[textdecode({1})]%;\
      /let help_command=$[substr(help_string,0,strstr(help_string," "))]%;\
      /let help_desc=$[substr(help_string,strstr(help_string," "))]%;\
      /echo -aCgreen -p - $[pad(help_command,-20)] @{Cyellow}%{help_desc}%;\
      /shift%;\
    /done%;\
  /endif

/def -i help_list=/help-list
/def -i helplist=/help-list

/help_add /help_helplist maintain a list of help-commands

/def -i help_helplist=\
  /echo -aB Help for help-list:%;\
  /echo /help_add <command> <short description> Add a command to be shown on help-list%;\
  /echo /help_list%;\
  /echo /helplist%;\
  /echo /help-list                              Show added help-commands.

/if (!loaded_help_list_file) \
  /echo -p @{Cgreen}% Help list loaded, @{xBCyellow}/help-list@{xnCgreen} to show helps available%;\
  /endif
/set loaded_help_list_file 1
