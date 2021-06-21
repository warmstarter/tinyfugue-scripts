/loaded squish.tf

/set squish_author=Cheetah@M*U*S*H
/set squish_info=Squishes strings
/set squish_url=https://github.com/Sketch/tinyfugue-scripts
/set squish_version=1.0.0

/require helplist.tf

/help_add /help_squish Squishes strings

/def -i help_squish = \
  /echo -aB squish help:%;\
  /echo This needs a help writeup

;;  squish(s1)
;;  squish(s1, s2)
;;          (str) Returns <s1> with runs of <s2> (default space) compressed
;;          into one occurrence.
;;

/def -i squish=\
  /let squishstring=%{1}%;\
  /let squishchar=$[({#} > 1) ? {2} : " "]%;\
  /while (strstr({squishstring}, strrep({squishchar}, 2)) > -1) \
    /test squishstring := replace(strrep({squishchar}, 2), \
                                  {squishchar}, \
                                  {squishstring}) %;\
  /done%;\
  /return {squishstring}
