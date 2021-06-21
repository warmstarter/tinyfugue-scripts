/loaded reconnect.tf

/set reconnect_author=QBFreak
/set reconnect_info=Keeps you connected to worlds
/set reconnect_url=
/set reconnect_version=1.0.0

/require helplist.tf

/help_add /help_reconnect Reconnects you to worlds

/def -i help_reconnect = \
  /echo -aB reconnect help:%;\
  /echo This needs a help write-up

;;; reconnect.tf - Automatically reconnect to disconnected TinyFugue worlds
;;;  QBFreak <qbfreak@qbfreak.net> 4/29/2017

/def -Fp1 -ag -E'!{intentional_disconnect} & {autoreconnect_enable}' -hDISCONNECT -T'tiny.*' autoreconnect_hook = /connect %1
/def -Fp1 -ag -E'{intentional_disconnect} & {autoreconnect_enable}' -hDISCONNECT -T'tiny.*' reset_autoreconnect = /set intentional_disconnect=0
/def -Fp1 -E'{autoreconnect_enable}' -mregexp -h'SEND ^QUIT$' -T'tiny.*' quithook = /set intentional_disconnect=1

;;; These were added here, but they might be better in another place
/def cc = /connect $[world_info()]
/def connect_all = /mapcar /connect $(/listworlds -s)

/def autoreconnect = \
	/if (%1 =~ "") \
		/autoreconnect_status %; \
	/elseif (%1 =~ "status") \
		/autoreconnect_status %; \
	/elseif (%1 =~ "enable") \
		/autoreconnect_enable %; \
	/elseif (%1 =~ "disable") \
		/set autoreconnect_enable=0%; \
		/echo % Auto Reconnect disabled.%; \
	/endif

/def autoreconnect_enable = \
	/set autoreconnect_enable=1%; \
	/echo % Auto Reconnect enabled.

/def autoreconnect_status = \
	/if (%autoreconnect_enable) \
		/echo % Auto Reconnect is enabled %; \
	/else \
		/echo % Auto Reconnect is disabled %; \
	/endif %; \

/autoreconnect_enable
