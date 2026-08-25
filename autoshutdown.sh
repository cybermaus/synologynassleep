#!/bin/bash
# suggested location is in /volume1/scripts/autoshutdown.sh
# suggested run is from the WEB-UI scheduler, at boot as root

# Start with $SLEEP before even checking, and
# needs $IDLE_REQUIRED time inactive
# so the minimum on time is $SLEEP+$IDLE_REQUIRED
SLEEP=600
IDLE_REQUIRED=900

# we ignore $IOMARGIN IO in $INTERVAL seconds
INTERVAL=5
IOMARGIN=1000

LOGFILE="/var/log/autoshutdown.log"
LOCKFILE="/var/log/autoshutdown.pid"

# TODO autodiscover the drives
DISKS=(sda sdb sdc sdd)


# Get IO read+write to disk in $INTERVAL
get_io()
{
    local disk="$1"

    awk -v d="$disk" '$3 == d {
        print $6 + $10
    }' /proc/diskstats 2>>$LOGFILE
}


# first cycle to logfile, as debug to check permissions
# Done before PID log, so false start attempt are seen in log file
echo "$(date): starting with new cycle" >$LOGFILE
chmod a+r $LOGFILE
awk '$0 ~ /sd. / { print }' /proc/diskstats >>$LOGFILE 2>&1

# Prevent multiple copies running and record pid
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Another instance is already running."
    exit 1
fi
echo "$$" >&9
chmod a+r $LOCKFILE

# Sleep a bit after boot, do not immediately shut down
echo "$(date): staring with $SLEEP seconds sleep" >>$LOGFILE
sleep $SLEEP


# actual looping and checking code
idle_since=0
previous=0

while true; do

    current=0
    for disk in "${DISKS[@]}"; do
        (( current += $(get_io "$disk") ))
    done
#       echo "$(date): $current" >>$LOGFILE

    diff=$((current - previous))
    if (( current <= previous + $IOMARGIN )); then
        if [ "$idle_since" -eq 0 ]; then
            idle_since=$(date +%s)
                        echo "$(date): no significant I/O detected; starting timer" >> $LOGFILE
        fi

                now=$(date +%s)
        elapsed=$((now - idle_since))
        if [ "$elapsed" -ge "$IDLE_REQUIRED" ]; then
            echo "$(date): no significant I/O for ${IDLE_REQUIRED}s; shutting down" >> $LOGFILE
                        /bin/sync
            /sbin/shutdown -h now
            exit 0
        fi
        else
        if [ "$idle_since" -ne 0 ]; then
                        idle_since=0
                        echo "$(date): significant I/O; ${diff} in ${INTERVAL}s; resetting timer" >> $LOGFILE
                fi
        fi

    previous=$current
    sleep "$INTERVAL"
done
