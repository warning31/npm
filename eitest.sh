#!/usr/bin/env bash
 
# Eitest Script for cPanel Servers
 
#Get Sinkhole IP
 
echo Enter Destination IP from the Detection Information Summary CBL report or press enter if the Destination IP is 192.42.116.41
read input
 
mkdir -p /root/support/detect-eitest && cd $_
script=eitest-monitor.sh
(
cat <<'EITESTSCRIPT'
#!/usr/bin/env bash
sinkhole=${input:-"192.42.116.41"}
while true; do
 connect=$(netstat -tpn | grep $sinkhole);
 if [[ $connect ]]; then
 PID=$(echo $connect | awk '{print$7}' | cut -d '/' -f1);
 (lsof -p $PID > eitest-files-$PID.log &)
 echo $connect >> eitest-connection-log.txt;
 fi
sleep 0.01
done
EITESTSCRIPT
) > $script
 
 
# Start Process Detection Script 
 
chmod 755 eitest-monitor.sh
screen -S eitest-monitor -dm bash -c './eitest-monitor.sh'
 
 
# Wait Until a Eitest Connection is Logged to Get the Infected User
 
echo
echo
echo Monitoring the Network for Eitest Activity Now ... ... ... ... ...
echo ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ...
until  [ -e eitest-connection-log.txt ]; do
 sleep 60
done
 
 
sleep 15
RED='\033[0;31m'
NC='\033[0m' # No Color
file=$(ls -lah | grep eitest-files-[0-9] | tail -1 | awk {'print $9'})
user=$(tail -1 $file | awk {'print $3'})
echo 
echo -e "${RED}Eitest Connection Detected for user ${user}! Initiating Clamscan using Yara Signatures on Account...${NC}"
echo
 
echo "Do you want to initiate a Clamscan on this account now? [Y/N] This will install clamscan and the necessary custom yara rules if not installed already."
read input
if [ $input == "y" ] || [ $input == "Y" ]; then
 echo Proceeding...
else
 echo Terminating Script now...
 screen=$(screen -ls | grep eitest-monitor | awk {'print $1'})
 screen -X -S $screen quit
 exit
fi
 
#Check for Clamscan and Install if Necessary
 
if [ -f /usr/local/cpanel/3rdparty/bin/clamscan ]; then
 echo Clamscan is installed. Proceeding.
 echo
else
 echo Installing Clamscan...
 echo
 /scripts/update_local_rpm_versions --edit target_settings.clamav installed
 /scripts/check_cpanel_rpms --fix --targets=clamav
fi
 
echo Git the Eitest Yara Signatures for Clamscan... 
echo
 
if [ -f /root/support/detect-eitest/lw-yara/lw.hdb ]; then
 echo Custom Yara Rules are installed. Proceeding.
 echo
else
 echo Installing Custom Yara Rules...
 echo
 git clone https://github.com/Hestat/lw-yara.git
fi
 
# Start Clamscan With Eitest Yara Rules for the User
 
/usr/local/cpanel/3rdparty/bin/clamscan -ir -l scanresults.txt -d lw-yara/lw-rules_index.yar -d lw-yara/lw.hdb /home/$user
 
#Kill Screen
 
screen=$(screen -ls | grep eitest-monitor | awk {'print $1'})
screen -X -S $screen quit
 
#Print Results
 
wd=$(pwd)
echo Scan Complete! Results: $wd/scanresults.txt
