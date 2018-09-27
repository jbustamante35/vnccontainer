#!/bin/bash

echo $@
fldr=$1
lang=$(echo $2 | cut -f 1 -d _)
app=$(echo $2 | cut -f 2 -d _)
cmd=/phytoMorph_public_deploy/matlab/DEwrapper
set -- "${1}" $lang $app "${@:3}"
echo $@
echo $cmd ${@:3}
