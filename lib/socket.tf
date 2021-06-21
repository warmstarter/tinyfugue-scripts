/loaded socket.tf

/set socket_author=QBFreak
/set socket_info=Returns a sorted socket list
/set socket_url=
/set socket_version=1.0.0

/require helplist.tf

/help_add /help_socket Returns a sorted socket list

/def -i help_socket = \
  /echo -aB socket help: %; \
  /echo This needs a help write-up

;;; QBFreak's sorted tab extensions - 4/28/2017 - qbfreak@qbfreak.net
;;; Whoo! Now you can specify the order the worlds appear!
;;;  use /set worldorder=Worldname1 Worldname2 Worldname3
;;;  disconnected worlds are still excluded from the list
;;;  if you specify some worlds but not all, the missing worlds will be appended to the end in the order the sockets were connected
;;;  if worldorder is blank, it will fall back to the list of connected sockets (the old way)

;;; Only full worlds need to be added to the list if using vwstatus.tf

/def sortedsockets = \
        /if (%1 =~ "-a") \
                /let _inval=$(/listsockets -s) %; \
        /else \
                /let _inval=$(/@listsockets -s -mregexp ^[^:]+\$) %; \
        /endif %; \
        /if (worldorder =~ "") \
                /result "%_inval" %; \
        /endif %; \
        /let _unsortedsockets=%_inval %; \
        /let _sorder=%worldorder %; \
        /let _unspecifiedsockets=%_unsortedsockets %; \
        /let _os=$(/first %worldorder) %; \
        /while (_os !~ "") \
                /let _unsort=%_unspecifiedsockets %; \
                /let _unspecifiedsockets=%; \
                /let _us=$(/first %_unsort)%; \
                /while (_us !~ "") \
                        /if (%_os =~ %_us) \
                                /let _retval=%_retval %_us %; \
                        /else \
                                /let _unspecifiedsockets=%_unspecifiedsockets %_us %; \
                        /endif %; \
                        /let _unsort=$(/rest %_unsort) %; \
                        /let _us=$(/first %_unsort) %; \
                /done %; \
                /let _sorder=$(/rest %_sorder) %; \
                /let _os=$(/first %_sorder) %; \
        /done %; \
;       Using /echo strips the leading space from variable values
        /let _retval=%_retval $(/echo %_unspecifiedsockets) %; \
        /result "$(/echo %_retval)"
