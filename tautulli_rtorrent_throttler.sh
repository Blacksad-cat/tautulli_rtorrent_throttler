#!/bin/bash

#MIT License

#Copyright (c) 2019 Blacksad-cat

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.


# Path to xmlrpc2scgi.py script
XMLRPC2SCGI=/home/blacksad/rtorrent-vagrant/scripts/xmlrpc2scgi.py

# Rtorrent connexion settings
# You can find your scgi port in your rtorrent.rc file. Default is 5000
RTORRENT_ADR=127.0.0.1
SCGI_PORT=5000

# All IPs in that list won't cause any throttling on plex input connexion
# Usually, you want put your local network in that list
# => Space separated list of networks in cibr or range format
WHITE_LIST="192.168.1.0/24"

# Max upload speed in B/s (from Mbps x131072)
# This script use this value and apply the amount of bandwidth needed by plex as throttling
MAX_UPLOAD_RATE=6553600

# If true, will cause download throttling as well  
THROTTLE_UPLOAD=true

# Max download speed in B/s (from Mbps x131072)
MAX_DOWNLOAD_RATE=52428800

# Factor in % of upload throttle. 
# 30% to 50% helps smooth streaming
DOWNLOAD_THROTTLE_FACTOR=30

# Security factor in % that will be apply on throttling
SAFETY_FACTOR=10

# Map and lock file used for data persistence
MAP_FILE=/tmp/plex_throttler_map
LOCK_FILE=/tmp/plex_throttler.lock

# Log file path
LOG_FILE=/var/log/plex_throttler.log
# Maximum log file number of lines
LOG_SIZE=2048

# Timeout offset in minutes added to playing duration before removing throttling 
SAFETY_TIMEOUT=5

# Timeout before removing throttling when video is paused
PAUSE_TIMEOUT=15

date_now=`date +%x`
time_now=`date +%T`
msg_hd="[$date_now $time_now]"

declare -A timing_map

print_help() {
	echo "tautulli_rtorrent_throttler"
	echo ""
	echo "Description: That script allows to automatically throttle rTorrent/ruTorrent when Plex Media Server streams to external clients"
	echo ""
	echo "Dependencies: "
	echo "   - Local Tautully server monitoring a local or distant Plex Media Server"
	echo "   - Local or distant rTorrent instance (scgi port must be expose... Only local...)"
	echo ""
	echo "Note: You must edit the scritp to set access, bandwidth and timing prior using"
	echo ""
	echo "Usage: tautulli_rtorrent_throttler [OPTION] <params...>"
	echo "Options:"
	echo "   -play <ip_address> <session_id> <remaining_duration> <stream_bandwidth>"
	echo "      Cause throtlling for remaining stream duration"
	echo "   -resume <ip_address> <session_id> <remaining_duration> <stream_bandwidth>"
	echo "      Cause throtlling for remaining stream duration"
	echo "   -watched <ip_address> <session_id> <remaining_duration> <stream_bandwidth>"
	echo "      Cause throtlling for remaining stream duration"
	echo "   -pause <ip_address> <session_id> <remaining_duration> <stream_bandwidth>"
	echo "      Cause throtlling for the next 15 min (default set pause time)"
	echo "   -stop <ip_address> <session_id> "
	echo "      Stop throtlling "
	echo "   -check "
	echo "      Check if streams are playing and apply needed throttling or remove it"
	echo "   -help "
	echo "      Print this help"
}

log_msg() {
    echo "$msg_hd $1" >> $LOG_FILE
}

print_msg() {
    log_msg "$1"
    echo "$msg_hd $1"
}

# Check if first param is in white list and exit script if so
check_white_list() {
    if [ `echo "$1" | grepcidr $WHITE_LIST` == "$1" ]; then
        exit 0
    fi
}

# Add number of minutes passed as 1st param to actual time and returns it
date_add_min() {
    timeout=`date +%s`
    let "timeout=$timeout + (60 * $1)"
    echo $timeout
}

# Add or modify map entry
# $1: key
# $2: value
set_stream() {
    (
    flock -x 199
    if [ -f "$MAP_FILE" ]; then
        source -- "$MAP_FILE"
    else
        print_msg "Creating map file"
        touch "$MAP_FILE"
        chmod 666 "$MAP_FILE"
    fi

    timing_map[$1]=`date_add_min $2`:$3

    declare -p timing_map > "$MAP_FILE"
    ) 199>$LOCK_FILE
}

apply_throttling() {
	#print_msg "$XMLRPC2SCGI -p scgi://$RTORRENT_ADR:$SCGI_PORT throttle.global_down.max_rate.set '' $1"
	result=`$XMLRPC2SCGI -p scgi://$RTORRENT_ADR:$SCGI_PORT throttle.global_down.max_rate.set '' $1`
	if [ "$result" != "0" ]; then
		print_msg "Unable to apply download limit: $result"
	fi
	
	#print_msg "$XMLRPC2SCGI -p scgi://$RTORRENT_ADR:$SCGI_PORT throttle.global_up.max_rate.set '' $2"
	result=`$XMLRPC2SCGI -p scgi://$RTORRENT_ADR:$SCGI_PORT throttle.global_up.max_rate.set '' $2`
	if [ "$result" != "0" ]; then
		print_msg "Unable to apply upload limit: $result"
	fi
}

# Check if throttling is needed and apply it
# Remove throttling if all playing done or pause timeout
check_for_throttling() {
    if [ -f "$MAP_FILE" ]; then
        (
        flock -x 199
        source -- "$MAP_FILE"
        now_sec=`date +%s`
        bandwidth_to_throttle=0
        for i in "${!timing_map[@]}"
        do
            if [ "$i" != "applied" ]; then
                IFS=':' read -ra stream_arr <<< "${timing_map[$i]}"
                if [ "${stream_arr[0]}" -gt $now_sec ]; then
                    let "remains=(${stream_arr[0]} - $now_sec) / 60"
                    print_msg "Remains $remains min. on stream $i"
                    let "bandwidth_to_throttle=$bandwidth_to_throttle + ${stream_arr[1]}"
                else
                    print_msg "Stream $i done"
                    unset timing_map[$i]
                fi
            fi
        done

        if [ $bandwidth_to_throttle -gt 0 ]; then
            if [ "${timing_map[applied]}" != "$bandwidth_to_throttle" ]; then
                bandwidth_to_throttle_adj=$(($bandwidth_to_throttle*(100+$SAFETY_FACTOR)/100))
                upload_limit=$(($MAX_UPLOAD_RATE-$bandwidth_to_throttle_adj))
                if [ "$THROTTLE_UPLOAD" == "true" ]; then
                    download_limit=$(($MAX_DOWNLOAD_RATE-($bandwidth_to_throttle*($DOWNLOAD_THROTTLE_FACTOR+$SAFETY_FACTOR)/100)))
                else
                    download_limit=0
                fi
                print_msg "External streams requiere $(($bandwidth_to_throttle/1024))kB/s. Throttling set at $(($download_limit/1024))/$(($upload_limit/1024)) kB/s"
                timing_map[applied]="$bandwidth_to_throttle"
                apply_throttling $download_limit $upload_limit
            fi
        else
            if [ "${timing_map[applied]}" != "FALSE" ]; then
                print_msg "No external client remaining. Throttling removed."
                timing_map[applied]="FALSE"
                apply_throttling 0 0
            fi
        fi

        declare -p timing_map > "$MAP_FILE"
        ) 199>$LOCK_FILE
    fi
}

clean_logs() {
    tail -n $LOG_SIZE $LOG_FILE > /tmp/dummy.log
	cat /tmp/dummy.log > $LOG_FILE
	#chmod 666 $LOG_FILE
}

case "$1" in
# <ip_adr> <stream_id> <remaining_duration> <needed_bandwidth>
-play)
    check_white_list $2
    print_msg "Play $3 on $2 remains $4 min. timeout by $(($4 + $SAFETY_TIMEOUT)) min. Needed bandwidth $(($5 / 8))kBps"
    set_stream "$2-$3" "$(($4 + $SAFETY_TIMEOUT))" "$(($5 * 1024 / 8))"
    ;;

# <ip_adr> <stream_id> 
-stop)
    check_white_list $2
    print_msg "Stop $3 on $2 timeout now"
    set_stream "$2-$3" "0" "0"
    ;;

# <ip_adr> <stream_id> <remaining_duration> <needed_bandwidth>
-resume)
    check_white_list $2
    print_msg "Resume $3 on $2 remains $4 min. timeout by $(($4 + $SAFETY_TIMEOUT)) min. Needed bandwidth $(($5 / 8))kBps"
    set_stream "$2-$3" "$(($4 + $SAFETY_TIMEOUT))" "$(($5 * 1024 / 8))"
    ;;

# <ip_adr> <stream_id> <remaining_duration> <needed_bandwidth>
-pause)
    check_white_list $2
    print_msg "Pause $3 on $2 remains $4 min. timeout by $PAUSE_TIMEOUT min. Needed bandwidth $(($5 / 8))kBps"
    set_stream "$2-$3" "$PAUSE_TIMEOUT" "$(($5 * 1024 / 8))"
    ;;

# <ip_adr> <stream_id> <remaining_duration> <needed_bandwidth>
-watched)
    check_white_list $2
    print_msg "Video $3 about to be watched on $2 remains $4 min. timeout by $(($4 + $SAFETY_TIMEOUT)) min. Needed bandwidth $(($5 / 8))kBps"
    set_stream "$2-$3" "$(($4 + $SAFETY_TIMEOUT))" "$(($5 * 1024 / 8))"
    ;;

-check)
    check_for_throttling
    clean_logs
    ;;

-help)
    print_help
    ;;

*)
    print_msg "Unhandled param $1"
	print_help
    exit 1
    ;;
esac

exit 0
