#!/bin/bash

# Environment setup
export PATH=$PATH:$HOME/.local/bin
base_dir="/var/safenode-manager/services"

# Current time for influx database entries
influx_time=$(date +%s%N | awk '{printf "%d0000000000\n", $0 / 10000000000}')
time_min=$(date +"%M")

# Counters
total_rewards_balance=0
total_nodes_running=0
total_nodes_killed=0

# Arrays
declare -A dir_pid
declare -A dir_peer_ids
declare -A node_numbers
declare -A node_details_store

# Fetch node overview from node-manager
sudo -E $HOME/.local/bin/safenode-manager status --details > /tmp/influx-resources/nodes_overview
if [ $? -ne 0 ]; then
    echo "Failed to get node overview from safenode-manager."
    exit 1
fi

# Process nodes
for dir in "$base_dir"/*; do
    if [[ -f "$dir/safenode.pid" ]]; then
        dir_name=$(basename "$dir")
        dir_pid["$dir_name"]=$(cat "$dir/safenode.pid")
        node_number=${dir_name#safenode}
        node_numbers["$dir_name"]=$node_number
        node_details=$(grep -A 12 "$dir_name - " /tmp/influx-resources/nodes_overview)

        # Skip if node status is ADDED
        if [[ $node_details == *"- ADDED"* ]]; then
            continue
        fi

        if [[ $node_details == *"- RUNNING"* ]]; then
            total_nodes_running=$((total_nodes_running + 1))
            status=TRUE
        else
            total_nodes_killed=$((total_nodes_killed + 1))
            status=FALSE
        fi

        peer_id=$(echo "$node_details" | grep "Peer ID:" | awk '{print $3}')
        dir_peer_ids["$dir_name"]="$peer_id"
        rewards_balance=$(echo "$node_details" | grep "Reward balance:" | awk '{print $3}')
        total_rewards_balance=$(echo "scale=10; $total_rewards_balance + $rewards_balance" | bc -l)

        # Format for InfluxDB
        node_details_store[$node_number]="nodes,id=$dir_name,peer_id=$peer_id status=$status,pid=${dir_pid[$dir_name]}i,records=$(find "$dir/record_store" -type f | wc -l)i,rewards=$rewards_balance $influx_time"
    fi
done

# Sort and print node details for InfluxDB
for num in $(echo "${!node_details_store[@]}" | tr ' ' '\n' | sort -n); do
    echo "${node_details_store[$num]}"
done

# Output total nodes and rewards
echo "nodes_totals rewards=$total_rewards_balance,nodes_running=${total_nodes_running}i,nodes_killed=${total_nodes_killed}i $influx_time"

# Measure latency and print to InfluxDB
latency=$(ping -c 4 8.8.8.8 | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
echo "nodes latency=$latency $influx_time"

# Grep for "us as BAD" in the logs and count all occurrences
bad_occurrences=$(grep -r "us as BAD" /var/log/safenode/ | wc -l)
echo "nodes_errors us_as_BAD_count=${bad_occurrences}i $influx_time"

# Calculate total storage of the node services folder and print to InfluxDB
total_disk=$(du -s "$base_dir" | cut -f1 | awk '{printf "%.0f\n", $1/1024}')
echo "nodes_totals total_disk=${total_disk}i $influx_time"



