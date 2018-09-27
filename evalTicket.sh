#!/bin/bash
# Usage: evalTicket.sh [ticket] [target] [command]
# ticket: iRODS hex code verification
# target: directory for extracting/exporting data
# command: 'iget' to extract data (iget) 'iput' to export data (iput)

# Parse iRODS input file to get ticket and data 
var=$2
var=$(echo ${var:0:1})
type=$1

case $var in
'#')
        ;;
*)
    case $type in
    iput)
        ticket=$(echo $2 | cut -f 1 -d ,)
        target=$(echo $2 | cut -f 2 -d ,)
        source=/loadingdock/userdata/dataout
        printf "Using ticket ${ticket} to ${type} ${source} into ${target}\n"
        iput -v -t $ticket -r $source $target
        ;;

    iget)
        ticket=$(echo $2 | cut -f 1 -d ,)
        source=$(echo $2 | cut -f 2 -d ,)
        target=/loadingdock/userdata/datain/
        printf "Using ticket ${ticket} to ${type} ${source} into ${target}\n"
        iget -v -t $ticket -r $source $target
        ;;

    *)
        ;;
    esac
esac

