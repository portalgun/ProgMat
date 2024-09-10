#!/bin/bash
wins=$(wmctrl -l | awk '$4~/^Prog:/ {$1=$2=$3="";print substr($0,4)}')
wmctrl -c "$wins"
