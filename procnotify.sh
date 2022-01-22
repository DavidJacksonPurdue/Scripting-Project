#!/bin/bash

#Do not insert code here

#DO NOT REMOVE THE FOLLOWING TWO LINES
git add $0 >> .local.git.out
git commit -a -m "Lab 2 commit" >> .local.git.out
git push >> .local.git.out || echo

# cycles per second
hertz=$(getconf CLK_TCK)

checkCPU=0
checkMEM=0
needNotify=0
memExceed=0
cpuExceed=0

function check_arguments {

  CHECKIFNUM="^[0-9]+([.][0-9]+)?$"
	#If number of arguments is less than 4, exit. 
	if [ "$1" -lt 4 ]; then
		echo "USAGE: "
    echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
    echo "There need to be at least four arguments"
    exit 0
  fi
  #If first argument is not a number, then it's not a PID, so exit
  if ! [[ "$2" =~ $CHECKIFNUM ]] ; then
    echo "USAGE: "
    echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
    echo "Please ensure that your first argument is the processID. (It's gotta be a number you silly)"
    exit 0
  fi
  #If last argument is not a number, then it's not the time interval, so exit
  if ! [[ ${@:$#} =~ $CHECKIFNUM ]] ; then
    echo "USAGE: "
    echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
    echo "Please ensure that your last argument is the time interval to measure. (This also gotta be a number)"
    exit 0
  fi
  #Third Argument needs to be -cpu or -mem. Fourth needs to be a number, this checks both of those factors
  if [ "$3" == "-cpu" ] ; then
    if ! [[ $4 =~ $CHECKIFNUM ]] ; then
      echo "USAGE: "
      echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
      echo "Please ensure your max cpu % is a number"
      exit 0
    else
      CPU_MAX_PERC=$4
      let checkCPU=1
    fi
  elif [ "$3" == "-mem" ] ; then
    if ! [[ $4 =~ $CHECKIFNUM ]] ; then
      echo "USAGE: "
      echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
      echo "Please ensure your mem maximum is a number representing max kB"
      exit 0
    else
      MEM_MAX=$4
      let checkMEM=1
    fi
  else
    echo "USAGE: "
    echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
    echo "Please ensure that you specify whether you wish to monitor memory or cpu or both"
    exit 0
  fi
  #If there are 6 arguments, then repeat previous check for arguments 5 and 6
  if [ "$1" -eq 6 ] ; then
    if [ "$5" == "-cpu" ] ; then
      if ! [[ $6 =~ $CHECKIFNUM ]] ; then
        echo "USAGE: "
        echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
        echo "Please ensure your max cpu % is a number"
        exit 0
      else
        CPU_MAX_PERC=$6
        let checkCPU=1
      fi
    elif [ "$5" == "-mem" ] ; then
      if ! [[ $6 =~ $CHECKIFNUM ]] ; then
        echo "USAGE: "
        echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
        echo "Please ensure your mem maximum is a number representing max kB"
        exit 0
      else
        MEM_MAX=$6
        let checkMEM=1
      fi
    else
      echo "USAGE: "
      echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
      echo "Please ensure that you specify whether you wish to monitor memory or cpu or both"
      exit 0
    fi
  #There needs to be either 4 or 6 arguments, anything else is illegal
  elif [ "$1" -eq 5 ] ; then
    echo "USAGE: "
    echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
    echo "There need to be either 4 or 6 arguments, no other number"
    exit 0
  elif [ "$1" -gt 6 ] ; then
    echo "USAGE: "
    echo "$0 {process id} -cpu {utilization percentage} -mem {maximum memory in kB} {time interval}"
    echo "There need to be either 4 or 6 arguments, no other number"
    exit 0
  fi
}

function init
{

	PID=$1 #This is the pid we are going to monitor

	TIME_INTERVAL=${@:$#} #Time interval is the last argument

}

#This function calculates the CPU usage percentage given the clock ticks in the last $TIME_INTERVAL seconds
function jiffies_to_percentage {
	
	#Get the function arguments (oldstime, oldutime, newstime, newutime)

	#Calculate the elpased ticks between newstime and oldstime (diff_stime), and newutime and oldutime (diff_stime)

	#You will use the following command to calculate the CPU usage percentage. $TIME_INTERVAL is the user-provided time_interval
	#Note how we are using the "bc" command to perform floating point division
  diff_stime=$( echo "$4-$2" | bc -l)
  diff_utime=$( echo "$3-$1" | bc -l)

	echo "100 * ( ($diff_stime + $diff_utime) / $hertz) / $TIME_INTERVAL" | bc -l
}


#Returns a percentage representing the CPU usage
function calculate_cpu_usage {

	#CPU usage is measured over a periode of time. We will use the user-provided interval_time value to calculate 
	#the CPU usage for the last interval_time seconds. For example, if interval_time is 5 seconds, then, CPU usage
	#is measured over the last 5 seconds


	#First, get the current utime and stime (oldutime and oldstime) from /proc/{pid}/stat
  oldutime=$( awk '{print $14}' /proc/$PID/stat )
  oldstime=$( awk '{print $15}' /proc/$PID/stat )
	#Sleep for time_interval
  sleep $TIME_INTERVAL
	#Now, get the current utime and stime (newutime and newstime) /proc/{pid}/stat
  newutime=$( awk '{print $14}' /proc/$PID/stat )
  newstime=$( awk '{print $15}' /proc/$PID/stat )
	#The values we got so far are all in jiffier (not Hertz), we need to convert them to percentages, we will use the function
	#jiffies_to_percentage

  percentage=$(jiffies_to_percentage $oldutime $oldstime $newutime $newstime)


	#Return the usage percentage
	echo "$percentage" #return the CPU usage percentage
}

function calculate_mem_usage
{
	#Let us extract the VmRSS value from /proc/{pid}/status
  mem_usage=$( awk '/VmRSS/ {print $2}' /proc/$PID/status )
  #if cpu was not checked, then wait has not occured, so sleep needs to occur here
  if [ 0 -eq $checkCPU ] ; then
    sleep $TIME_INTERVAL
  fi

	#Return the memory usage
	echo "$mem_usage"
}

function notify
{
	#We convert the float representating the CPU usage to an integer for convenience. We will compare $usage_int to $CPU_THRESHOLD
	cpu_usage_int=$(printf "%.f" $1)
  func_name=$( awk '/Name/ {print $2}' /proc/$PID/status )
  command_line=$( cat "/proc/$PID/cmdline" )
  echo "Process ID: $PID" > notification
  echo >> notification
  echo "Process Name: $func_name" >> notification
  echo >> notification
  #echo "Command: $command_line" >> notification
  #echo >> notification
  echo $(printf "CPU Usage: %.2f %%" $cpu_usage) >> notification
  echo >> notification
  echo "MEM_USAGE: $mem_usage kB" >> notification
  echo >> notification
	#Check if the process has exceeded the thresholds. Only the correct exceedings are sent
  if [ 1 -eq $cpuExceed ] ; then
    echo "CPU Exceeded" > title
    echo "CPU Exceeded" >> notification
    echo >> notification
  fi
  if [ 1 -eq $memExceed ] ; then
    echo "Memory Exceeded" >> title
    echo "Memory Exceeded" >> notification
    echo >> notification
  fi
  /usr/bin/mailx -s "$title" $USER < notification
  echo "Process has exceeded a limit, a notification has been sent out"
}


check_arguments $# $@

init $1 $@

#The monitor runs forever
while [ -n "$(ls /proc/$PID)" ] #While this process is alive
do
	#part 1
	cpu_usage=$(calculate_cpu_usage)
  mem_usage=$(calculate_mem_usage)
  #needNotify is a check put in place to ensure that notify doesn't occur twice if mem and cpu exceed
  if [ 1 -eq $checkCPU ] ; then
    if [ 1 -eq $(echo $cpu_usage  $CPU_MAX_PERC | awk '{if ($1 > $2) print 1; else print 0}') ] ; then
      let needNotify=1
      let cpuExceed=1
    fi
  fi
  if [ 1 -eq $checkMEM ] ; then
    if [ 1 -eq $(echo $mem_usage $MEM_MAX | awk '{if ($1 > $2) print 1; else print 0}') ] ; then
      let needNotify=1
      let memExceed=1
    fi
  fi
  if [ 1 -eq $needNotify ] ; then
    notify
  fi
  let needNotify=0
  let cpuExceed=0
  let memExceed=0

	#Call the notify function to send an email to $USER if the thresholds were exceeded
	#notify $cpu_usage $mem_usage

done
