#!/bin/bash

start=$SECONDS

sleep 1
for i in {1..1000}
do
#        printf "HellowWhorled ${i} times"
done

runtime=$(($SECONDS-$start)) 

echo -e "\n\nArguments: ${@}"
printf "Start: ${start}\n"
printf "Excecution time: ${runtime}\n"
