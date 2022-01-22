#!/bin/bash

#Do not insert code here

#DO NOT REMOVE THE FOLLOWING TWO LINES
git add $0 >> .local.git.out
git commit -a -m "Lab 2 commit" >> .local.git.out
git push >> .local.git.out || echo

# cycles per second
hertz=$(getconf CLK_TCK)

TIME_INTERVAL=10

NUM_PROCESSES=20

CHECK_ALL=0

SORT_CPU=1

SORT_VM=0

function check_arguments () {
    #Extract arguments
    echo "Extract arguments..."
    #ARGS is the list of arguments in array form
    ARGS=($@)
    #num arguments must be > 0 for this function to do anything
    if [ $1 -gt 0 ]; then
      for (( i=1; i <= $1; i++ )); do
        if [ "${ARGS[$i]}" == "-c" ] ; then
          let SORT_CPU=1
        fi
        if [ "${ARGS[$i]}" == "-m" ] ; then
          let SORT_VM=1
          let SORT_CPU=0
        fi
        if [ "${ARGS[$i]}" == "-p" ] ; then
          let NUM_PROCESSES=${ARGS[$i+1]}
        fi
        if [ "${ARGS[$i]}" == "-t" ] ; then
          if [ ${ARGS[$i+1]} -le 0 ] ; then
            echo "USEAGE:"
            echo "./procmon.sh [-c] [-m] [-p number-processes displayed] [-t time interval] [-a]"
            echo "Please ensure your time interval is greater than 0"
            exit 0
          else
            let TIME_INTERVL=${ARGS[$i+1]}
          fi
        fi
        if [ "${ARGS[$i]}" == "-a" ] ; then
          let CHECK_ALL=1
        fi
    done
    fi
}

#This function calculates the CPU usage percentage given the clock ticks in the last $TIME_INTERVAL seconds
function jiffies_to_percentage () {
	
	#Get the function arguments (oldstime, oldutime, newstime, newutime)

	#Calculate the elpased ticks between newstime and oldstime (diff_stime), and newutime and oldutime (diff_stime)

	#You will use the following command to calculate the CPU usage percentage. $TIME_INTERVAL is the user-provided time_interval
	#Note how we are using the "bc" command to perform floating point division
  diff_stime=$( echo "$4-$2" | bc -l)
  diff_utime=$( echo "$3-$1" | bc -l)

	echo "100 * ( ($diff_stime + $diff_utime) / $hertz) / $TIME_INTERVAL" | bc -l
}

#This function takes as arguments the cpu usage and the memory usage that were last computed
function generate_top_report () {
    echo "Top Report:"
    tot_proc=0
    run_proc=0
    sleep_proc=0
    zom_proc=0
    stop_proc=0
    now=$(date)
    mem_tot=$( awk '/MemTotal:/ {print $2}' /proc/meminfo )
    up_time_sec=$( awk '{print $1}' /proc/uptime )
    let up_time_sec=$(printf "%.0f" "$up_time_sec")
    up_time_days=$(( up_time_sec / 86400 ))
    let up_time_sec=$(( up_time_sec - $(( up_time_days * 86400 )) ))
    up_time_hours=$(( up_time_sec / 3600 ))
    let up_time_sec=$(( up_time_sec - $(( up_time_hours * 3600 )) ))
    up_time_minutes=$(( up_time_sec / 60 ))
    user_count=$( who | wc -l )
    echo $(mpstat -u 2 5) > CPU_STATS
    ld_avg1=$( awk '{print $1}' /proc/loadavg )
    ld_avg2=$( awk '{print $2}' /proc/loadavg )
    ld_avg3=$( awk '{print $3}' /proc/loadavg )
    echo "Old Times" > OLD_TIMES
    for procid in /proc/*; do
      if ! [ "$procid" == "/proc/self" ] && ! [ "$procid" == "/proc/net" ] && ! [ "$procid" == "/proc/thread-self" ] ; then
        if [ -a "$procid/stat" ] ; then
          u_time=$( awk '{print $14}' "$procid/stat" )
          s_time=$( awk '{print $15}' "$procid/stat" )
          pid=$( awk '{print $1}' "$procid/stat" )
          echo ":$pid:  $u_time  $s_time" >> OLD_TIMES
        fi
      fi
    done
    sleep 5
    echo "0 0 0 0 0 0 0 0 0 0 0 0 0 0" > PID_LIST
    for procid in /proc/*; do
      if ! [ "$procid" == "/proc/self" ] && ! [ "$procid" == "/proc/net" ] && ! [ "$procid" == "/proc/thread-self" ] ; then
        if [ -a "$procid/stat" ] ; then
          uid=$( awk '/Uid:/ {print $2}' "$procid/status" )
          user=$( getent passwd "$uid" | awk -F: '{print $1}' )
          cur_pid=$( awk '{print $1}' "$procid/stat" )
          cur_virt=$( awk '{print $1}' "$procid/statm" )
          cur_nice=$( awk '{print $19}' "$procid/stat" )
          cur_status="$( awk '{print $3}' "$procid/stat" )"
          if [ 'R' == $cur_status ]; then
            let run_proc=$run_proc+1
          elif [ 'S' == $cur_status ]; then
            let sleep_proc=$sleep_proc+1
          elif [ 'T' == $cur_status ]; then
            let stop_proc=$stop_proc+1
          elif [ 'Z' == $cur_status ]; then
            let zom_proc=$zom_proc+1
          fi
          let tot_proc=$tot_proc+1
          cur_u_time=$( awk '{print $14}' "$procid/stat" )
          cur_s_time=$( awk '{print $15}' "$procid/stat" )
          old_u_time=$( awk '/:'$cur_pid':/ {print $2}' OLD_TIMES )
          old_s_time=$( awk '/:'$cur_pid':/ {print $3}' OLD_TIMES )
          cpu_perc=$( jiffies_to_percentage $old_u_time $old_s_time $cur_u_time $cur_s_time )
          if [ 1 -eq $(echo $cpu_perc 100.0 | awk '{if ($1 > $2) print 1; else print 0}') ] ; then
            cpu_perc=100.00
          fi
          cur_mem=$( awk '{print $2}' "$procid/statm" )
          cur_mem_perc=$( echo "$cur_mem / $mem_tot" | bc -l )
          cur_command="$( awk '{print $2}' "$procid/stat" )"
          cur_Shmem="$( awk '/RssShmem/ {print $2}' "$procid/status" )"
          cur_RssFile="$( awk '/RssFile/ {print $2}' "$procid/status" )"
          cur_shr=$(( cur_Shmem + cur_RssFile ))
          proc_time=$(( cur_u_time + cur_s_time ))
          proc_sec=$( echo "$proc_time / $hertz" | bc -l )
          let proc_sec=$( printf "%.0f" $proc_sec )
          proc_mil=$( echo "($proc_time / $hertz) - $proc_sec" | bc -l )
          let proc_mil=$( printf "%.0f" $( echo "$proc_mil * 100" | bc -l ) )
          if [ 0 -gt $proc_mil ] ; then
            let proc_mil=$(( proc_mil * -1 ))
          fi
          proc_min=$(( proc_sec / 60 ))
          let proc_sec=$(( proc_sec - $(( proc_min * 60 )) ))
          cur_priority=$( awk '{print $18}' "$procid/stat" )
          printf "%ld\t " $cur_pid >> PID_LIST
          printf "%s    \t " $user >> PID_LIST
          printf "%ld\t " $cur_priority >> PID_LIST
          printf "%ld\t " $cur_nice >> PID_LIST
          printf "%ld\t " $cur_virt >> PID_LIST
          printf "%ld\t " $cur_mem >> PID_LIST
          printf "%ld\t " $cur_shr >> PID_LIST
          printf "%c\t " $cur_status >> PID_LIST
          printf "%.2f\t " $cpu_perc >> PID_LIST
          printf "%.2f\t " $cur_mem_perc >> PID_LIST
          printf "%ld:%ld.%ld     \t " $proc_min $proc_sec $proc_mil >> PID_LIST
          printf "%s\n " $cur_command >> PID_LIST
        fi
     fi
    done 
    echo "$now, up $up_time_days days, $up_time_hours:$up_time_minutes, $user_count Users, load average: $ld_avg1, $ld_avg2, $ld_avg3"
    echo "Tasks: $tot_proc total, $run_proc running, $sleep_proc sleeping, $stop_proc stopped, $zom_proc zombies"
    cpu_user=$( awk '{print $24}' CPU_STATS )
    cpu_ni=$( awk '{print $25}' CPU_STATS )
    cpu_sys=$( awk '{print $26}' CPU_STATS )
    cpu_wa=$( awk '{print $27}' CPU_STATS )
    cpu_hi=$( awk '{print $28}' CPU_STATS )
    cpu_si=$( awk '{print $29}' CPU_STATS )
    cpu_st=$( awk '{print $30}' CPU_STATS )
    cpu_id=$( awk '{print $33}' CPU_STATS )
    echo $( printf "%.2f us, %.2f sy, %.2f ni, %.2f id, %.2f wa, %.2f hi, %.2f si, %.2f st" $cpu_user $cpu_sys $cpu_ni $cpu_id $cpu_wa $cpu_hi $cpu_si $cpu_st )
    mem_free=$( awk '/MemFree:/ {print $2}' /proc/meminfo )
    mem_cache=$( awk 'NR==5 {print $2}' /proc/meminfo )
    mem_used=$(( mem_tot - mem_free ))
    mem_buff=$( awk '/Buffers:/ {print $2}' /proc/meminfo )
    mem_buff_cache=$(( mem_cache + mem_buff ))
    echo "KiB Mem $mem_tot+ total, $mem_free+ free, $mem_used used, $mem_buff_cache buff/cache"
    swap_tot=$( awk '/SwapTotal:/ {print $2}' /proc/meminfo )
    swap_free=$( awk '/SwapFree:/ {print $2}' /proc/meminfo )
    swap_used=$(( swap_tot - swap_free ))
    mem_av=$( awk '/MemAvailable:/ {print $2}' /proc/meminfo )
    echo "Kib Swap $swap_tot+ total, $swap_free+ free, $swap_used used, $mem_av+ available Mem"
    printf "PID\t USER\t\t PR\t NI\t VIRT\t RES\t SHR\t S\t %%CPU\t %%MEM\t TIME+\t\t COMMAND\n" 
    if [ 1 -eq $CHECK_ALL ] ; then
      if [ 1 -eq $SORT_CPU ] ; then
        sort -k9 -n -r PID_LIST  > TOP_PRINT
        head -n $NUM_PROCESSES TOP_PRINT
      else
        sort -k5 -n -r PID_LIST  > TOP_PRINT
        head -n $NUM_PROCESSES TOP_PRINT
      fi
    else
      cat PID_LIST | grep $USER > PERSONAL_TOP
      if [ 1 -eq $SORT_CPU ] ; then
        sort -k9 -n -r PERSONAL_TOP  > TOP_PRINT
        head -n $NUM_PROCESSES TOP_PRINT
      else
        sort -k5 -n -r PERSONAL_TOP  > TOP_PRINT
        head -n $NUM_PROCESSES TOP_PRINT
      fi
    fi
}

#Returns a percentage representing the CPU usage
function calculate_cpu_usage () {

	#CPU usage is measured over a periode of time. We will use the user-provided interval_time value to calculate 
	#the CPU usage for the last interval_time seconds. For example, if interval_time is 5 seconds, then, CPU usage
	#is measured over the last 5 seconds


	#First, get the current utime and stime (oldutime and oldstime) from /proc/{pid}/stat


	#Sleep for time_interval
  sleep $TIME_INTERVAL
	#Now, get the current utime and stime (newutime and newstime) /proc/{pid}/stat

	#The values we got so far are all in jiffier (not Hertz), we need to convert them to percentages, we will use the function
	#jiffies_to_percentage
  percentage=$(jiffies_to_percentage $oldutime $oldstime $newutime $newstime)

	#Return the usage percentage
	echo "$percentage" #return the CPU usage percentage
}

check_arguments $# $@

#procmon runs forever or until ctrl-c is pressed.
while [ -n "$(ls /proc/$PID)" ] #While this process is alive
do
	generate_top_report
  sleep $TIME_INTERVAL
done
