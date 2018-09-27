#!/bin/bash
# Parse through config.json file to extract arguments 

fin=$1
str=$(echo $fin | tr "\n" " " | cut -f 2 -d [ | cut -f 1 -d ] | tr -d "\"" )

echo $str
