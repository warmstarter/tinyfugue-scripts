/loaded vworld.tf

/set vworld_author=Cheetah@M*U*S*H + QBFreak
/set vworld_info=Handles virtual worlds
/set vworld_url=https://github.com/Sketch/tinyfugue-scripts
/set vworld_version=3.0.0

/require helplist.tf
/require socket.tf
/require status.tf

/require textencode.tf
/require textutil.tf

/help_add /help_vworld Virtual Worlds and Status Bar

/def -i help_vworld = \
  /echo -aB vworld help: %; \
  /echo This needs a help write-up %; \
/echo Handle 'virtual' worlds. %; \
/echo This is a light API around connectionless sockets for adding, removing %; \
/echo and making sure they're connected, and have something to handle %; \
/echo 'sending' text to the world. %; \
/echo %; \
/echo It has been modified to include additional features including a statusbar

;;; NOTE: this assumes virtual worlds are named like:
; <world>:<virtual>

;;; /vw_create [-s<send_handler>] [-t<subtype>] <World Name>
; Creates a virtual world and ensures it's connected.
; Automatically defines a SEND hook that will call the given send handler
; when typing text to this world, or default to /vw_default_send_handler
; if not specified. The handler is called with the world name as its first
; argument, and the text typed to the world in the subsequent arguments.
; All virtal worlds have a type virtual.*, use -t to specify a subtype.
; For example -tspawn. will make the complete type virtual.spawn.
/def -i vw_create=\
  /if (!getopts("s:t:", "")) /return 0%; /endif%; \
  /addworld -T'virtual.%{opt_t}' %{*}%;\
  /let vw_mname=_vw_shook_$(/textencode %{*})%;\
  /def -T'virtual.*' -w'%{*}' -h'SEND *' %{vw_mname}=\
    %{opt_s-/vw_default_send_handler} %{*} %%{*}%;\
  /vw_ensure %{*}

;;; /vw_delete <World name>
; Deletes a virtual world, making sure to clean up after itself.
/def -i vw_delete=\
  /if (!vw_exists({1})) \
    /echo -A %% No virtual world named %{1}.%;\
    /return 0%;\
  /endif%;\
  /if ( vw_isconnected({1}) ) \
    /dc %{1}%;\
  /endif%;\
  /if (morepaused({1})) \
    /fg %{1}%;\
    /dokey flush%;\
  /endif%;\
  /if (world_info("name") =~ {1}) \
    /bg%;\
  /endif%;\
  /repeat -0 1 /unworld %{1}%;\
  /let vw_mname=_vw_shook_$(/textencode %{*})%;\
  /undef %{vw_mname}

;;; /vw_write <world>=<text>
; Writes text to a virtual world, making sure it exists and is connected,
; connecting to it if necessary.
/def -i vw_write=\
  /split %{*}%;\
  /let vw_world=%{P1}%;\
  /let vw_text=%{P2}%;\
  /if (!vw_exists({vw_world})) \
    /echo -A %% No virtual world named %{vw_world}.%;\
    /return 0%;\
  /endif%;\
  /vw_ensure %{vw_world}%;\
  /echo -w%{vw_world} %{vw_text}

;;; /vw_redirect [-k] [-m<matching>] <from>=<to>=<pattern>
; Redirects lines from world from matching pattern to virtual world to.
; Returns the number of the macro used to handle those lines.
; With -k it keeps those lines in the original world. Without (the default)
; it will gag them.
/def -i vw_redirect=\
  /if (!getopts("km:", "")) /return 0%; /endif%; \
  /let vw_attrs=%;\
  /if (!{opt_k}) \
    /test vw_attrs := strcat(vw_attrs, "g")%;\
  /endif%;\
  /let vw_matching=%{opt_m-%{matching}}%;\
  /split %{*}%;\
  /let vw_from=%{P1}%;\
  /split %{P2}%;\
  /let vw_to=%{P1}%;\
  /let vw_pattern=%{P2}%;\
  /if (!vw_exists({vw_to})) \
    /echo -A %% No virtual world named %{vw_to}.%;\
    /return 0%;\
  /endif%;\
  /let vw_mname=$[strcat("_vw_", \
                  $(/textencode %{vw_to}), \
                  "_", \
                  $(/textencode %{vw_from}), \
                  "_", \
                  $(/textencode %{vw_pattern}))]%;\
  /def -a%{vw_attrs} -m%{vw_matching} -t'$[escape("'", {vw_pattern})]' -w'%{vw_from}' -q %{vw_mname}=\
    /vw_write %{vw_to}=%%{*}%;\
  /return %?

;;; " fix for vim syntax highlighting

;;; vw_isconnected(<world>)
; Returns whether or not the virtual world specified is connected.
; Required because is_connected always returns 0 for connectionless worlds.
/def -i vw_isconnected=\
  /if (strlen($(/listsockets -s -Tvirtual.* %{1}))) \
    /let retval=$[substr($(/listsockets -Tvirtual.* %{1} %|\
                           /grep -v *LINES IDLE*),1,1) =~ "O"]%;\
    /return {retval}%;\
  /else \
    /return 0%;\
  /endif

;;; vw_exists(<world>)
; Returns whether world exists as a virtual world.
/def -i vw_exists=\
  /let retval=$(/listworlds -s -Tvirtual.* %{1})%;\
  /return !!strlen({retval})

;;; /vw_ensure <world>
; Ensure world is connected, connecting to it immediately if necessary.
/def -i vw_ensure=\
  /if (!vw_exists({1})) \
    /echo -A %% No virtual world named %{1}.%;\
    /return 0%;\
  /endif%;\
  /if ( !vw_isconnected({1}) ) \
    /connect -b %{1}%;\
  /endif

;;; /vw_default_send_handler <args>
; Called if no specific handler is set for a virtual world.
/def -i vw_default_send_handler=\
  /echo %{*}

;;;;;;;;;;;;; Integration of tabs


;;; returns the base world name (stuff before the :)
/def vw_tab_world=\
        /if (vw_exists({1})) \
                /return substr({1}, 0, strchr({1},":")) %;\
        /else \
                /return {1} %;\
        /endif

;;; returns the name of the tab (stuff after the :)
/def vw_tab_name=\
        /if (vw_exists({1})) \
                /return substr({1}, strchr({1},":")+1) %;\
        /else \
                /return "" %;\
        /endif

;;; in tf5, alt-left & alt-right switch worlds.
;;; this adds alt-up and alt-down for switching tabs within a world.

/def vw_nexttabafter=/let fullname=%1%;\
        /let socketlist=%2 %2%; \
        /let worldname=$[vw_tab_world(fullname)]%; \
        /while ($(/first %socketlist) !~ fullname) \
                /let socketlist=$(/rest %socketlist)%; \
        /done%; \
        /let socketlist=$(/rest %socketlist)%; \
        /while (vw_tab_world($(/first %socketlist)) !~ worldname) \
                /let socketlist=$(/rest %socketlist)%; \
        /done%;\
        /return $$(/first %socketlist)

;       Tweaked for QBFreak's sorted tab extensions 4/28/2017
;        changed the value from the list of connected sockets, to a list of connected sockets in the order the user has specified
/def vw_nexttab=/fg $[vw_nexttabafter(world_info(), $(/sortedsockets -a))]

/def vw_prevtab=/let tmpsocketlist=$(/sortedsockets -a)%;\
        /let socketlist=%; \
        /while (strlen(tmpsocketlist)) \
                /let socketlist=$(/first %tmpsocketlist) %socketlist%; \
                /let tmpsocketlist=$(/rest %tmpsocketlist)%; \
        /done%; \
        /fg $[vw_nexttabafter(world_info(), socketlist)]

/def vw_nextworldafter=/let fullname=%1%;\
        /let socketlist=%2 %2%; \
        /let worldname=$[vw_tab_world(fullname)]%; \
        /while ($(/first %socketlist) !~ fullname) \
                /let socketlist=$(/rest %socketlist)%; \
        /done%; \
        /let socketlist=$(/rest %socketlist)%; \
        /while (vw_exists($(/first %socketlist)) | vw_tab_world($(/first %socketlist)) =~ worldname ) \
                /let socketlist=$(/rest %socketlist)%; \
        /done%;\
        /return "$[escape("\\\"", $(/first %socketlist))]"

;; fix " for vim syntax hilighting - mhh

;       Tweaked for QBFreak's sorted tab extensions 4/28/2017
/def vw_nextworld=/fg $[vw_nextworldafter(world_info(), $(/sortedsockets -a))]

/def vw_prevworld=/let tmpsocketlist=$(/sortedsockets -a)%;\
        /let socketlist=%; \
        /while (strlen(tmpsocketlist)) \
                /let socketlist=$(/first %tmpsocketlist) %socketlist%; \
                /let tmpsocketlist=$(/rest %tmpsocketlist)%; \
        /done%; \
        /fg $[vw_nextworldafter(world_info(), socketlist)]

;;; in tf5, alt-left & alt-right switch worlds.
;;; this modifies these keys to actually switch worlds, not tabs
;;; it will go to an arbitrary tab within the first "different" world it
;;; finds in either direction

/def key_esc_right=/vw_nexttab
/def key_esc_left=/vw_prevtab
/def key_esc_up=/vw_nextworld
/def key_esc_down=/vw_prevworld

;;; the attributes to put before the fg, bg (no activity), or bg (has activity) world names
/set vw_tablist_fg_world_attrs=@{Cyellow,Cbgrgb001}
/set vw_tablist_bgworld_attrs=@{Ccyan,Cbgrgb001}
/set vw_tablist_bgmore_world_attrs=@{Cbrightred,Cbgrgb001}
/set vw_tablist_tab_attrs=@{hCwhite,Cbgrgb001}
;;; seperator between tabs within a world. 
;;;   - note: changing this and the next pair could well break certain aspects
;;;           of the tabs screen fitting part (I'll fix eventually)
;;; Definitely keep the sep and more bits as is, except for colors
/set vw_tablist_tab_sep=@{Cgray}|
;;; seperators between entire worlds.
/set vw_tablist_world_sep_l=@{Cgray,Cbgrgb001}[
/set vw_tablist_world_sep_r=@{Cgray}]
;;; Left and Right side of "more" numbers
/set vw_tablist_more_l=:
/set vw_tablist_more_r=
;;; left and right side of "much more" MM tag.
/set vw_tablist_muchmore_l=:
/set vw_tablist_muchmore_r=
;;; what to prepend to a dead (ie: !is_open()) world
/set vw_tablist_deadworld=!
;;; do we want to show number of lines of activity?
/set vw_tablist_show_lines=1
;;; do we want the entire world tab set to collapse to just the world name 
;;; when it's not active?
/set vw_tablist_collapse_world=1
;;; should collapsed tabs with activity expand even if the world isn't active?
/set vw_tablist_collapse_show_active=1

/def vw_get_tablist_size=\
        /if (regmatch("vw_tabs:([^:]*):", status_fields(2))) \
                /return %P1 %;\
        /else \
                /return columns() %;\
        /endif

;	Tweaked for QBFreak's sorted tab extensions 4/28/2017
/def vw_build_tabs=\
	/let _slist=$(/sortedsockets) %; \
	/let _w=$(/first %_slist) %;\
	/test _ret:="" %;\
	/while ( _w !~ "" ) \
		/test _ret := strcat(_ret, vw_tablist_world_sep_l)%;\
		/let _tlist=$(/@listsockets -s -mregexp ^%_w:) %;\
		/test _tlist := strcat(_w, " ", _tlist)%;\
		/let _t=$(/first %_slist) %;\
		/while ( _t !~ "" ) \
			/test _ret_item:="" %;\
			/test _new := moresize("", _t) %;\
			/if (_t !~ vw_tab_world(_t)) \
				/test _ret_item := strcat(_ret_item, vw_tablist_tab_sep) %;\
			/endif %;\
			/if (_t =~ fg_world()) \
				/test _ret_item := strcat(_ret_item, vw_tablist_fg_world_attrs )%;\
			/elseif (_new > 0) \
				/test _ret_item := strcat(_ret_item, vw_tablist_bgmore_world_attrs )%;\
			/elseif (_t !~ vw_tab_world(_t)) \
				/test _ret_item := strcat(_ret_item, vw_tablist_tab_attrs )%;\
			/else \
				/test _ret_item := strcat(_ret_item, vw_tablist_bgworld_attrs )%;\
			/endif %;\
			/if (!is_open(_t)) /test _ret_item := strcat(_ret_item, vw_tablist_deadworld) %; /endif %;\
			/test _ret_item := strcat(_ret_item, substr(_t, strchr(_t,":") > -1 ? strchr(_t,":")+1 : 0)) %;\
			/test _mt := ""%;\
			/if (_new > 0 & _new < 1000 & vw_tablist_show_lines) \
				/test _mt := strcat(vw_tablist_more_l, _new, vw_tablist_more_r) %;\
			/elseif (_new > 1000 & vw_tablist_show_lines) \
                                /test _mt := strcat(vw_tablist_muchmore_l, "MM", vw_tablist_muchmore_r) %;\
			/endif %;\
			/test _ret_item := strcat(_ret_item, _mt) %;\
			/if (!(vw_tablist_collapse_world & vw_tab_world(_t) !~ vw_tab_world(fg_world()) & (_new == 0 | (_new > 0 & !vw_tablist_collapse_show_active)))) \
				/test _ret := strcat(_ret, _ret_item) %;\
			/elseif (_t =~ vw_tab_world(_t)) \
				/test _ret := strcat(_ret, _ret_item) %;\
			/endif %;\
			/let _tlist=$(/rest %_tlist) %;\
			/let _t=$(/first %_tlist) %;\
		/done %;\
		/test _ret := strcat(_ret, vw_tablist_world_sep_r ) %;\
		/let _slist=$(/rest %_slist) %;\
		/let _w=$(/first %_slist) %;\
	/done %;\
	/test _dret:=decode_attr(_ret) %;\
	/test _avail_len:=vw_get_tablist_size() %;\
        /if (strlen(_dret) > _avail_len) \
        	/if (vw_exists(fg_world())) \
			/test _fg_loc:=strstr(_dret, vw_tab_name(fg_world())) %;\
		/else \
			/test _fg_loc:=strstr(_dret, fg_world()) %;\
		/endif %;\
		/test _cutoff:=strchr(_dret, "|[", _fg_loc - _avail_len/2 > 0 ? _fg_loc - _avail_len/2 : 0) %;\
	/else \
                /test _cutoff:=0 %;\
        /endif %;\
	/return tolower(substr({_dret}, _cutoff))

/set status_var_vw_tabs vw_build_tabs()

;;; QBFreak's tab extensions - 3/1/2006 - qbfrea@qbfreak.net
/status_add -r0 -B vw_tabs
/def -qi -Fp2147483647 -hACTIVITY|MORE|WORLD vw_update_activity_status = /repeat -0 1 /vw_update_activity
/def -p0 -aAg -hPREACTIVITY|ACTIVITY|BGTEXT|MORE|WORLD|CONNECT ignore_alerts

;;; Based on activity_status.tf
/def -i vw_update_activity = \
    /status_edit -r0 vw_tabs

/def -E'${world_name} !~ fg_world() & moresize("")' \
  -qi -Fp2147483647 -mglob -h'DISCONNECT' \
    vw_update_activity_disconnect_hook = \
        /activity_queue_hook ${world_name}%; \
        /vw_update_activity

/def -qi -Fp2147483647 -hPREACTIVITY|BGTEXT|SEND vw_update_activity_preactivity_hook = \
    /vw_update_activity_delayed

/def -i vw_update_activity_delayed = \
     /repeat -1 1 /vw_update_activity
