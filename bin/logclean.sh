#!/bin/bash

COMSYS='911\|Ananasi\|Anarch\|Arcanum\|Bastet\|BeatCourts\|Brujah\|BSD\|Bygone\|Camarilla\|CamOfficers\|CamProspect\|Carlsbad\|Changeling\|Civil\|Code\|Council\|CultOfEcstasty\|Dark Ages\|Debate\|Demon\|Elohim\|Fallen\|Fera\|Flirting\|FollowersOfSet\|Gaian\|Gangrel\|Garou\|GarouElder\|GarouKinfolk\|GarouShifter\|Giovanni\|Harpy\|Hengeoyokai\|HiddenMeadows\|Hunter\|IdyllWild\|Independent\|Internet\|Kuei-Jin\|Law\|LFG\|Mage\|Malakim\|Mediums\|Mortal\|Mortal+\|Mummy\|NC-17\|Nephandi\|Newbie\|Nosferatu\|OrpheusGroup\|Pentex\|Possessed\|Projector\|Public\|Radio\|Random\|Rules\|RuralGarou\|Sabbat\|SchreckNet\|Seelie\|Shadow\|Shovelhead\|SorcererPsych\|Staff\|Streetwise\|Technocracy\|TJRadio\|Toreador\|Traditions\|Tremere\|UC Prospect\|Unseelie\|UrbanGarou\|Vampire\|Ventrue\|VirtualAdepts\|Weather\|Wiki\|Wraith\|Wyrm'

DBWRITE='Writing reality out to disk. Please wait...\|Reality saved. Thank you for your patience.'

strip_comsys() {
  sed "/^\[$COMSYS\].*/d"
}

strip_dbwrite() {
  sed "/^$DBWRITE/d"
}

strip_ooc() {
  sed '/Announcement:\|<OOC>\|<<OOC>>\/From afar\|You paged\|Long distance to\|MAIL: You have a new\|You have voted\|ERROR/d'
}

strip_watch() {
  sed '/^\[+WATCH\].*/d'
}

main() {
  strip_comsys|strip_dbwrite|strip_ooc|strip_watch
}

main "@"
