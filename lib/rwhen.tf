/loaded rwhen.tf

/set rwhen_author=Cheetah@M*U*S*H
/set rwhen_info=Find timestamp for last time a certain output was seen
/set rwhen_url=https://github.com/Sketch/tinyfugue-scripts
/set rwhen_version=1.0.0

/require helplist.tf

/help_add /help_rwhen Information on last time certain output was seen

/def -i help_rwhen = \
  /echo -aB Recall When help:%;\
  /echo /rwhen                   Gives timestamp of last output to world%;\
  /echo /rwnen <text>            Gives timestamp last time <text> was seen

/def -i rwhen=\
  /let time=$(/recall -t"\%T \(\%a \%d \%b\)|" /1 %{*})%;\
  /if ({time} =~ "") \
    /echo -A %% Not lately.%;\
  /else \
    /echo -A %% Seen at: $[substr({time},0,strstr({time},"|"))]%;\
  /endif
