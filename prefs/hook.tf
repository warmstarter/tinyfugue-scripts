/if ((%{TERM} =~ "xterm") | (%{TERM} =~ "xterm-256color") & (%{TMUX} !~ "" )) \
  /def -i -h"WORLD" tmux_fg_title_hook=/tmux_title TinyFugue - ${world_name} (${world_character})%; \
/endif
