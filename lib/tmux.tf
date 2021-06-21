; This needs proper escaping
/def -i tmux_title = \
        /echo -r \033Ptmux;\033\033]0;%*\007\033\\

/set tmux_split_size -10

/def tmux_split = \
        /if ({1} =~ "up") \
                /sys tmux resize-pane -U %2 %;\
        /elseif ({1} =~ "down") \
                /sys tmux resize-pane -D %2 %;\
        /endif

/def tmux_splitpc = \
        /set split_size -15     %;\
        /split                  %;\
        /set split_size -10
