#!/bin/bash
# this runs as a @hourly cron task
# run
# crontab -e
  # power-on-server
    # 15 * * * * bash $HOME/pp0-forseti/scripts/power-on-server.sh
      # execute automatic update script and log every hour at **:15
    # 50 00 * * 0 /bin/bash -c 'cp $HOME/pp0-forseti/logs/power-on-server.log $HOME/pp0-forseti/backup_logs/power-on-server-$(date +\%Y\%m\%d).log'
      # saves weekly version of "power-on-server.log" on Sundays at 00:50 am
    # 55 00 * * 0 rm -f $HOME/pp0-forseti/logs/apt-get-autoupdater.log
      # deletes old weekly log on Sunday every week at 00:55 am
# requires etherwake and wakeonlan (apt-get)
# installed etherwake and wakeonlan because I had some issues with one or the other between updates, so I added both
# run Wake-on-LAN from rpi_cronjob_examples.txt
echo
echo "############################"
echo "Starting power-on-server"
date
echo

HOSTNUM=0
HOSTS=(
    10.100.0.1      # Router (Yggdrasil)
    10.100.0.11     # PotentPi1 (Odin [PiHole])
    10.100.0.12     # PotentPi2 (Mimir [Internal Dashboard & Unifi Controller])
    10.100.0.13     # PotentPi3 (Loki [Transmission Server])
    10.100.0.14     # PotentPi4 (Skadi [Deployment Station])
    10.100.0.15     # Vital Services File Server (TrueNAS)
    10.100.0.30     # Vital Services Cluster - Aesir1
    10.100.0.31     # Vital Services Cluster - Aesir2
    10.100.0.32     # Vital Services Cluster - Aesir3
    10.100.0.60     # Homelab File Server (Huginn)
    10.100.0.61     # Home Cluster - Vanir1
    # 10.100.0.62   # Home Cluster - Vanir2
    # 10.100.0.63   # Home Cluster - Vanir3
)
HOSTSDOWN=0
MACADDRS=(
    38:f7:cd:c1:e3:cb   # 10.100.0.1
    e4:5f:01:67:86:e6   # 10.100.0.11
    e4:5f:01:0a:99:5c   # 10.100.0.12
    dc:a6:32:d4:70:25   # 10.100.0.13
    dc:a6:32:d3:cc:dc   # 10.100.0.14
    ac:1f:6b:b2:0d:9e   # 10.100.0.15
    b0:5c:da:3c:47:cd   # 10.100.0.30
    b0:5c:da:3b:97:10   # 10.100.0.31
    f8:b4:6a:a0:7e:6f   # 10.100.0.32
    dc:a6:32:dc:46:2b   # 10.100.0.60
    f4:4d:30:6d:40:ab   # 10.100.0.61
    # 10.100.0.62
    # 10.100.0.63
)
PING="/bin/ping -q -c1"
WAITTIME=10

### functions

function wake_up() {
  echo wakeonlan ${MACADDRS[${HOSTNUM}]}
  echo wakeonlan -p 9 ${MACADDRS[${HOSTNUM}]}
  echo sudo etherwake ${MACADDRS[${HOSTNUM}]}
}

# first sleep to allow system to connect to network and time to break out if needed
# sleep 60

for HOST in ${HOSTS[*]}; do
  if ! ${PING} ${HOST} > /dev/null
  then
    HOSTSDOWN=$((${HOSTSDOWN}+1))
    echo "${HOST} is down $(date)"
    # try to wake
    wake_up ${HOSTNUM}
    sleep 10
    wake_up ${HOSTNUM}
    sleep 10
    wake_up ${HOSTNUM}
    sleep 10
    wake_up ${HOSTNUM}
    sleep 10
    #restart networking
    /etc/init.d/networking reload
    sleep 15
    # try to wake
    wake_up ${HOSTNUM}
    sleep 2
    wake_up ${HOSTNUM}
    sleep 2
    HOSTNUM=$(($HOSTNUM+1))
  else
    echo "${HOST} was up at $(date)"
  fi
done

# reboot
if [[ ${HOSTSDOWN} -eq ${#HOSTS[@]} ]]
  then
  echo "Pi is rebooting"
fi
/sbin/shutdown -r now
