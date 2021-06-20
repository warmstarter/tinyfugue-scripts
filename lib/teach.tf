/loaded teach.tf
; It's basically a tf version of /teach to help teach
; other folks some fun points of tf!
;
/def teach= \
        /send -w${world_name} pose types into tf --> [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;

/def esend= \
        /send -w${world_name} th > [ansi(h,lit(%{*}))]%; \
        /eval -s0 %{*} %;
