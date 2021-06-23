/loaded vwstatus.tf

/set vwstatus_author=QBFreak
/set vwstatus_info=Status Bar for Virtual Worlds
/set vwstatus_url=
/set vwstatus_version=2.2.0

/require helplist.tf
/require socket.tf
/require status.tf
/require vworld.tf

;;; This is generall incompatible with activity_status.tf and activity_status2.tf
;;; It is possible to run both activity_status an vwstatus on separate status lines,
;;; but there doesn't seem to be much point in doing so outside of debugging.

;;; To make full use of vwstatus, it's expected that your Virtual Worlds are named
;;; in the format <world>:<virtual> in order for it to be aware of which type each
;;; is as well as to pull out a shortened name.

;;; It's recommended that virtual worlds have a prefix for their type like 'Virtual'
;;; as there are likely other scripts that you will want to have treat these worlds
;;; differently. There is nothing within this script that requires that, though.

;;; TinyFugue-Rebirth has a bug in their parser that will drop the color on ']' within
;;; the statusbar. This issue does not exist within other variants oF TF5, but I am
;;; working with them to resolve it.

/require textencode.tf
/require textutil.tf

/help_add /help_vwstatus Status Bar for Virtual Worlds

/def -i help_vwstatus = \
  /echo -aB vwstatus help: %; \
  /echo This needs a help write-up %; \

;;; the attributes to put before the fg, bg (no activity), or bg (has activity) world names
/set vw_tablist_fg_world_attrs=@{Cyellow,Cbgrgb001}
/set vw_tablist_bgworld_attrs=@{Cwhite,Cbgrgb001}
/set vw_tablist_bgmore_world_attrs=@{Cbrightred,Cbgrgb001}
/set vw_tablist_tab_attrs=@{Ccyan,Cbgrgb001}
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

/status_add -r0 -B vw_tabs
/def -qi -Fp2147483647 -hACTIVITY|MORE|WORLD vw_update_activity_status = /repeat -0 1 /vw_update_activity
/def -p0 -aAg -hPREACTIVITY|ACTIVITY|BGTEXT|MORE|WORLD|CONNECT ignore_alerts

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

;;; These need to get redefined to call vw_update_activity
;;; otherwise in some situations when scrolling down, the
;;; status bar will not update.

/def key_pgdn = \
     /dokey_pgdn %; \
     /vw_update_activity
/def key_tab = \
     /dokey page %; \
     /vw_update_activity
