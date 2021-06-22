/loaded tmux.tf

/set tmux_author=
/set tmux_info=Interact with tmux
/set tmux_url=
/set tmux_version=1.0.0

/require helplist.tf

/help_add /help_tmux Interact with tmux

/def -i help_tmux = \
  /echo -aB tmux help: %; \
  /echo /tmux_title <title>           Sets the <title> of the window %; \
  /echo /tmux_split [up|down]         Splits the tmux pane in selected manner %; \
  /echo /tmux_splitpc                 Splits the tmux pane 50%% larger 

/def -i tmux_title = \
       /echo -r \033Ptmux;\033\033]0;%*\007\033\\\

;;; Below still needs some work

/set split_size -10

/def tmux_split = \
        /if ({1} =~ "up") \
                /sys tmux resize-pane -U %2 %; \
        /elseif ({1} =~ "down") \
                /sys tmux resize-pane -D %2 %; \
        /endif

/def tmux_splitpc = \
        /set split_size -15     %; \
        /tmux_split             %; \
        /set split_size -10
