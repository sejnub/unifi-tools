#!/bin/bash

VERSION=9

echo "INFO: ####### Running add-dns version $VERSION ########"


#############
# Constants #
#############

# Additional static DNS entries
ADDITIONAL_ENTRIES_URL=https://raw.githubusercontent.com/sejnub/unifi-tools/master/add-dns/additional-manual-dns.json

# Define Filenames
KEKS_FN=/tmp/unifi_cookie.txt
STAT_RESULT_FN=/tmp/unifi-stat.json
ADD_DNS_RESULT_FN=/tmp/unifi-add-dns-result.json
LIST_CLIENTS_RESULT_FN=/tmp/unifi-list-clients-result#.json

# The name of the json file on the unifi controller on cloudkey
#CONFIG_GATEWAY_JSON_FN=/srv/unifi/data/sites/default/config.gateway.json

# The name of the json file on the unifi controller on rpi-02-docker
CONFIG_GATEWAY_JSON_FN=/home/pi/unifi-to-backup/config.gateway.json

ENV_FILE_FN=/usr/local/etc/sejnub-credentials.env


############################################
# Get credentials and insert into commands #
############################################
# Set credentials for unifi controller if not already set
# The variables $UNIFI_USERNAME, $UNIFI_PASSWD and $UNIFI_HOST must be set.

if [ -e $ENV_FILE_FN ]; then
  source $ENV_FILE_FN
else 
  echo "WARNING: The environment file $ENV_FILE_FN could not be found."
fi

if [ -z "$UNIFI_HOST" ]; then
  echo "ERROR: The required credentials are not set. Exiting."
  exit -2
else
  echo "INFO: The required credentials seem to be set."
  echo "INFO: unifi controller = $UNIFI_HOST."
fi  

# TODO: add -s for silent again
LOGIN_CMD="     curl -s -k -d '{\"username\":\"$UNIFI_USERNAME\",\"password\":\"$UNIFI_PASSWD\",\"remember\":false,\"strict\":true}' -c $KEKS_FN -k -X POST https://$UNIFI_HOST:8443/api/login"
STAT_CMD="      curl -s -k -b $KEKS_FN -X GET  https://$UNIFI_HOST:8443/api/s/default/stat/alluser"
PROVISION_CMD=" curl    -k -b $KEKS_FN -X POST https://$UNIFI_HOST:8443/api/s/default/cmd/devmgr --data-binary '{\"mac\":\"f0:9f:c2:11:6b:ef\",\"cmd\":\"force-provision\"}' --insecure"


#############
# Functions #
#############

function login {
  login_result=$(eval $LOGIN_CMD)
  ok=$(echo "$login_result" | jq -r .meta.rc)
  if [ "$ok" == "ok"  ]; then
    echo "INFO: Login to '$UNIFI_HOST' was successful."
  else
    echo "ERROR: Login to '$UNIFI_HOST' failed. Exiting."
    exit -2
  fi
}

function fetch {
  rm -f $STAT_RESULT_FN

  echo "INFO: Trying to fetch stat from unifi controller."
  stat_result=$(eval $STAT_CMD)
  ok=$(echo "$stat_result" | jq -r .meta.rc)
  if [ ! "$ok" == "ok"  ]; then
    echo "WARNING: The first try to fetch stat did not work so I log in to get a new cookie."
    login
    echo "INFO: Trying to fetch stat from unifi controller."
    stat_result=$(eval $STAT_CMD)
    ok=$(echo "$stat_result" | jq -r .meta.rc)
    if [ ! "$ok" == "ok"  ]; then
      echo "ERROR: Could not get the stat from the controller. Exiting."
      exit -2
    else  
      echo "INFO: The second try to fetch stat was successful."
    fi
  else
    echo "INFO: The first try to fetch stat was successful."
  fi

  echo "$stat_result" > $STAT_RESULT_FN
}


########################################
# Get the stat entries from controller #
########################################
if [ ! -e $KEKS_FN ]; then
  echo "INFO: There is no cookie, so I login to the controller to create one." 
  login
else
  echo "INFO: There is a cookie, so I do not need to login to the controller to create one." 
fi

fetch 


##################################################
# Get the additional DNS entries from repository #
##################################################
# Download the file additional-manual-dns.json from github via curl and overwrite the local one with it.
# This way the container that this script goes into can run forever, you only have to edit the file 
# https://github.com/sejnub/unifi-tools/blob/master/add-dns/additional-manual-dns.json and then run the script again.

GET_ADDITIONAL_ENTRIES_CMD="curl -s -k $ADDITIONAL_ENTRIES_URL"

addentries_result=$(eval $GET_ADDITIONAL_ENTRIES_CMD) 

# Test if it is valid json
#echo "< $addentries_result >"
type_result=$(echo "$addentries_result" | jq type)

if [ ! "$type_result" == '"array"' ]; then
  echo "ERROR: Could not get the additional-manual-dns.json. Taking the default one."
else  
  echo "INFO: The file additional-manual-dns.json is loaded via curl and is added to the DNS entries."
  echo "$addentries_result" > additional-manual-dns.json
fi


if [ -e $STAT_RESULT_FN ]; then

  #################################################################
  # Do the jq stuff to generate the json for the unifi controller #
  #################################################################
  echo "INFO: Filtering stat-result with jq"
  jq -f add-dns.jq   --argfile manualentries additional-manual-dns.json $STAT_RESULT_FN > $ADD_DNS_RESULT_FN
  # The following line is for another use case
  #jq -f list-clients.jq $STAT_RESULT_FN > $LIST_CLIENTS_RESULT_#FN

  ###################################################
  # Copy the resulting json to the unifi controller #
  ###################################################
  echo "INFO: Copying the resulting file to $CONFIG_GATEWAY_JSON_FN on the host $UNIFI_HOST."
  # -q = quiet (remove this option to identify problems)
  sshpass -p "$UNIFI_SSH_PASSWD" scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $ADD_DNS_RESULT_FN $UNIFI_SSH_USERNAME@$UNIFI_HOST:$CONFIG_GATEWAY_JSON_FN
  sshpass_exit_code=$?
  if [ $sshpass_exit_code -ne 0 ]; then
    echo "ERROR: Could not copy the JSON file to the host $UNIFI_HOST. Exiting."
    exit -2   
  else  
    echo "INFO: JSON file was successfully copied to the unifi controller."
  fi
  
  ########
  # Done #
  ########
  echo "INFO: Now you should manually force a provisioning on the usg via the unifi controller. Try https://192.168.1.30:8443/manage/site/default/devices/1/200"
  echo " "
  echo "================"
  echo "=== Success ===="
  echo "================"


  ##########################
  # WIP: Provision the usg #
  ##########################
  # Why does the following always say {"meta":{"rc":"error","msg":"api.err.LoginRequired"},"data":[]}
  #
  # Next line is the copied curl from the chrome developer tool
  # curl 'https://192.168.1.30:8443/api/s/default/cmd/devmgr' -H 'Connection: keep-alive' -H 'Accept: application/json, text/plain, */*' -H 'Sec-Fetch-Dest: empty' -H 'X-Csrf-Token: vamthU2JEiQixnf2yzR3ALCn3AiukoWt' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.106 Safari/537.36' -H 'Content-Type: application/json;charset=UTF-8' -H 'Origin: https://192.168.1.30:8443' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://192.168.1.30:8443/manage/site/default/devices/list/1/100?pp=W3siaSI6ImRldmljZXxmMDo5ZjpjMjoxMTo2YjplZiIsInMiOnsiYWN0aXZlVGFiIjoiY29uZmlndXJlIn19XQ%3D%3D' -H 'Accept-Language: en' -H 'Cookie: unifises=xFo1qYhgR56eVWoOQT3WB4U9cArdkOEp; csrf_token=vamthU2JEiQixnf2yzR3ALCn3AiukoWt' --data-binary '{"mac":"f0:9f:c2:11:6b:ef","cmd":"force-provision"}' --compressed --insecure
  
  #echo "INFO: Trying to provision the usg with the command 'force-provision'."
  #provision_result=$(eval $PROVISION_CMD) 
  #echo "'$provision_result'"
  #ok=$(echo "$provision_result" | jq -r .meta.rc)
  #if [ ! "$ok" == "ok"  ]; then
  #  echo "Warning: The first try to provision did not work so I log in to get a new cookie."
  #  login
  #  echo "INFO: Trying to provision the usg with the command 'force-provision'."
  #  provision_result=$(eval $PROVISION_CMD) 
  #  echo "'$provision_result'"
  #  ok=$(echo "$provision_result" | jq -r .meta.rc)
  #  if [ ! "$ok" == "ok"  ]; then
  #    echo ERROR: Provision did not work.
  #  else
  #    echo INFO: Provision was successful.
  #  fi 
  #else
  #  echo INFO: Provision was successful.
  #fi 


else 
  # TODO: Make this the if branch and the successfull branch the else!
  echo "ERROR: There is no file with stat results so there is nothing to parse. This line should never be reached. Fix the script!"
fi


#eof
