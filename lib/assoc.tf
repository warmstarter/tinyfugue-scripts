/loaded assoc.tf

/set assoc_author=Cheetah@M*U*S*H
/set assoc_info=Association of key/value pairs
/set assoc_url=https://github.com/Sketch/tinyfugue-scripts
/set assoc_version=1.0.0

/require helplist.tf

/help_add /help_assoc Association of key/value pairs

/def -i help_assoc = \
  /echo -aB assoc help:%;\
    /echo /assoc <key>=<value>          Assign <value> to <key> %;\
    /echo /rassoc <key>                 Echoes back value associated with <key> %;\
    /echo /lassoc [<prefix>]            Lists keys starting with prefix. More or less informational only. %;\
    /echo /llassoc [<prefix>]           Lists key => value pairs starting with prefix. For informational use. %;\
    /echo /mapassoc <prefix>=<cmd>      Execute "<cmd> <key>=<value>" for each key=value pair matching <prefix> %;\
    /echo   %;\
    /echo Association of key/value pairs. %;\
    /echo Keys can contain any character. For the effect of several separate %;\
    /echo hashes/dictionaries/whatever, it's best to use a prefix. %;\
    /echo IE: /assoc users Cheetah=27  /assoc users Walker=5 

/require textencode.tf
/require lisp.tf

;;; Mostly for maintainability. Change outside this script not recommended.
/set __assoc_prefix=assoc_

/def -i assoc=\
  /split %{*}%;\
  /if (!strlen({P2})) \
    /_unassoc $(/textencode %{P1})%;\
  /else \
    /let rest=%{P2}%;\
    /_assoc $(/textencode %{P1}) %{rest} %;\
  /endif

/def -i rassoc=\
  /let varname=$(/textencode %{*})%;\
  /eval /echo %%{%{__assoc_prefix}%{varname}}

/def -i lassoc=\
  /let lassoc_pattern=%{__assoc_prefix}$(/textencode %{*})* %;\
  /let lassoc_list=$(/listvar -s %{lassoc_pattern}) %;\
  /echo $(/mapcar /_lassoc_decode %{lassoc_list})

/def -i mapassoc=\
  /split %{*}%;\
  /let mapassoc_cmd=%{P2}%;\
  /let mapassoc_pattern=%{__assoc_prefix}$(/textencode %{P1})* %;\
  /let mapassoc_list=$(/listvar -s %{mapassoc_pattern}) %;\
  /mapcar /_mapassoc %{mapassoc_list}

/def -i llassoc=\
  /mapassoc %{*}=/_llassoc
/def -i _llassoc=\
  /split %{*}%;\
  /echo %{P1}=>%{P2}

/def -i _mapassoc=\
  /let mapassoc_key=$(/_lassoc_decode %{1})%;\
  /let mapassoc_value=$(/rassoc %{mapassoc_key})%;\
  /let mapassoc_args=%{mapassoc_key}=%{mapassoc_value}%;\
  /eval %{mapassoc_cmd} %%{mapassoc_args}

/def -i _lassoc_decode=\
  /echo $(/textdecode $[substr({*},strlen({__assoc_prefix}))])

/def -i _unassoc=/unset %{__assoc_prefix}%{1}

/def -i _assoc=\
  /let varname=%{1}%;\
  /shift%;\
  /set %{__assoc_prefix}%{varname}=%{*}
