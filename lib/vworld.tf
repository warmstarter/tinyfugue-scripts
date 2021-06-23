/loaded vworld.tf

/set vworld_author=Cheetah@M*U*S*H + Heller + QBFreak
/set vworld_info=Handles virtual worlds
/set vworld_url=https://github.com/Sketch/tinyfugue-scripts
/set vworld_version=3.0.0

/require helplist.tf
/require socket.tf

/require textencode.tf
/require textutil.tf

/help_add /help_vworld Virtual Worlds

/def -i help_vworld = \
  /echo -aB vworld help: %; \
  /echo Handle 'virtual' worlds. %; \
  /echo This is a light API around connectionless sockets for adding, removing %; \
  /echo and making sure they're connected, and have something to handle %; \
  /echo 'sending' text to the world. %; \
  /echo %; \
  /echo It has been modified to include additional features. %; \
  /echo vwstatus is an optional status bar that can be use with this.

;;; If you plan to use this with vwstatus, it is expected for virtual worlds to
;;; use the following naming scheme: <world>:<virtual>

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

;;; The tab parts below may not be particularly useful without
;;; vwstatus.tf might be worth moving these over there or
;;; elsewhere.

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
        /while (vw_exists($(/first %socketlist)) | \
		vw_tab_world($(/first %socketlist)) =~ worldname ) \
                /let socketlist=$(/rest %socketlist)%; \
        /done%;\
        /return "$[escape("\\\"", $(/first %socketlist))]"

;; fix " for vim syntax hilighting - mhh

/def vw_nextworld=/fg $[vw_nextworldafter(world_info(), $(/sortedsockets -a))]

/def vw_prevworld=/let tmpsocketlist=$(/sortedsockets -a)%;\
        /let socketlist=%; \
        /while (strlen(tmpsocketlist)) \
                /let socketlist=$(/first %tmpsocketlist) %socketlist%; \
                /let tmpsocketlist=$(/rest %tmpsocketlist)%; \
        /done%; \
        /fg $[vw_nextworldafter(world_info(), socketlist)]

;;; in tf5, alt-left & alt-right switch worlds.
;;; this modifies alt-left and alt-right for switching tabs within a world.
;;; it will go to an arbitrary tab within the first "different" world it
;;; finds in either direction
;;; this adds ctrl-left-up & ctrl-right to actually switch worlds, not tabs

/def key_esc_left=/vw_prevtab
/def key_esc_right=/vw_nexttab
/def key_ctrl_left=/vw_prevworld
/def key_ctrl_right=/vw_nextworld
