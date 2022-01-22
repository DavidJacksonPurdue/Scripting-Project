This is a school project where I created various bash scripts to perform different actions. There are four executable bash scripts in this repository, the rest are various
test input/output files that I used for debugging. I will now do a quick walkthrough of the various scripts, all scripts were made to work on a LINUX machine with a bash
interpreter:

phonecheck: This is a simple script that varifies if a user inputted phone number is in valid phone number format. Input can be in the form of a file or written directly into
the command line. The script will echo valid or invalid depending.

pwcheck: This is a simple script to rate the strength of a user inputted password. A score is echoed out into the terminal out of 15. Input can be performed in the same manner
as the previous

procmon: This is a complicated bash script which emulates the functionality of the "top" command. The script will live print data about all active processes currently running
on the cpu, such as PID, Time alive, CPU usage percentage, Memory usage percentage, owner, etc. Additionally, overall data about all processes running on the cpu will be printed
as well, such as total up time, load average, total users running processes, total processes, total running processes, total sleeping, total zombie, etc. Flags can be used to
change the functionality of the script. "-c" flag will sort the current processes by cpu usage (default). The "-m" flag will sort by ram usage. The "-p" flag will change the number of 
processes that the script will print data about (by default, it is the top 20 in terms of cpu usage or ram usage). The "-t" flag will change the refresh rate in seconds (by defaut it
is 10). The "-a" flag will list all processes currently on the cpu (this can make the script very resource intensive). All of these flags are optional.

procnotify: This is another complicated bash script which can be run to notify a user if a process of theirs exceeds user defined threshold limits. The notification is sent via
an email of the process owner stored in the folder /usr/bin/mailx. Script must be executed via the command "procnotify {process id} -cpu {utilization percentage} 
-mem {maximum memory in kB} {time interval}" The first is obvious, to track a process you need to identify which process by its id. The second flag is where you define cpu
utilization threshold. The third is where you define the ram utilization threshold. The fourth flag is where you define how often that this process checks the utilization data
about another process in seconds (too small of values can result in the script becoming resource intensive. Value must be greater than 0)
