#!/bin/bash

# color
RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m' # Reset color

# settings
TARGET="$1"
MAX_HOPS=30
START_SIZE=1500
MIN_SIZE=500

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

echo "mturoute to $TARGET, $MAX_HOPS hops max, variable sized packets"
echo "* ICMP Fragmentation is not permitted. *"
echo "* Speed optimization is enabled. *"
echo "* Maximum payload is $START_SIZE bytes. *"

# Getting IP addresses along the way
HOPS=($(traceroute -n -m $MAX_HOPS "$TARGET" | awk '{print $2}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'))

HOP_NUM=1

for HOP in "${HOPS[@]}"; do
    if [[ "$HOP" == "*" ]]; then
        echo "$HOP_NUM  ...  no reply"
        ((HOP_NUM++))
        continue
    fi

    echo -n "$HOP_NUM  "  # Print number  hop
    ANIMATION=""
    LOW=$MIN_SIZE
    HIGH=$START_SIZE
    MTU=0

    while (( LOW <= HIGH )); do
        MID=$(( (LOW + HIGH) / 2 ))

        # run ping
        if timeout 1 ping -M do -c 1 -s $((MID - 28)) "$HOP" > /dev/null 2>&1; then
            MTU=$MID
            LOW=$((MID + 1))
            ANIMATION+="${GREEN}+${NC}"  # Plus if success
        else
            HIGH=$((MID - 1))
            ANIMATION+="${RED}-${NC}"   # Minus if there is an error
        fi

        # Draw the last animation without line breaks
        echo -ne "\r$HOP_NUM  $ANIMATION"
        sleep 0.05
    done

    if [ $MTU -gt 0 ]; then
        echo "  host: $HOP  max: $MTU bytes"
    else
        echo "  host: $HOP not responding"
    fi

    ((HOP_NUM++))
done
