#!/bin/bash

setuphold_match="\(.*\)(.*SETUPHOLD.*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\))"
setuphold_sub_line_1="\1(SETUP \2 \3 \4)"
setuphold_sub_line_2="\1(HOLD \2 \3 \5)"
setuphold="s/$setuphold_match/$setuphold_sub_line_1\n$setuphold_sub_line_2/"

recrem_match="\(.*\)(.*RECREM.*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\))"
recrem_sub_line_1="\1(RECOVERY \2 \3 \4)"
recrem_sub_line_2="\1(REMOVAL \2 \3 \5)"
recrem="s/$recrem_match/$recrem_sub_line_1\n$recrem_sub_line_2/"

triple_rval="s/( *\([-0-9]\+\) *)/( \1:\1:\1 )/g"

voltage="s/\((.*VOLTAGE[ \t]*\)\([\.0-9]\+\)\(.*)\)/\1 :\2: \3/"
temperature="s/\((.*TEMPERATURE[ \t]*\)\([\.0-9]\+\)\(.*)\)/\1 :\2: \3/"

cat $1 |    sed "$setuphold" | sed "$recrem" | sed "$triple_rval" | \
	    sed "$voltage" | sed "$temperature" 
