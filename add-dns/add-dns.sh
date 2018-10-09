#!/bin/bash

# Define URL of additional static DNS entries
ADDITIONAL_ENTRIES_URL=https://raw.githubusercontent.com/sejnub/unifi-tools/master/add-dns/additional-manual-dns.json

# Define Filenames
KEKS_FN=/tmp/unifi_cookie.txt
STAT_RESULT_FN=/tmp/unifi-stat.json
ADD_DNS_RESULT_FN=/tmp/unifi-add-dns-result.json
LIST_CLIENTS_RESULT_FN=/tmp/unifi-list-clients-result#.json

ENV_FILE_FN=/usr/local/etc/credentials.env

# Set credentials for unifi controller if not already set

# The variables $UNIFI_USERNAME, $UNIFI_PASSWD and $UNIFI_HOST must be set.

#echo Before sourcing \'$ENV_FILE\': '$UNIFI_HOST' = \'$UNIFI_HOST\'

if [ -e $ENV_FILE_FN ]; then
  source $ENV_FILE_FN
fi
#echo After  sourcing \'$ENV_FILE\': '$UNIFI_HOST' = \'$UNIFI_HOST\'


if [ -z "$UNIFI_HOST" ]; then
  echo "ERROR: The required credentials are not set. Exiting."
  exit -2
else
  echo "INFO: The required credentials are set."
fi  


# TODO: add -s for silent again
LOGIN_CMD="curl      -k -d '{\"username\":\"$UNIFI_USERNAME\",\"password\":\"$UNIFI_PASSWD\",\"remember\":false,\"strict\":true}' -c $KEKS_FN -k -X POST https://$UNIFI_HOST:8443/api/login"
STAT_CMD="curl       -k -b $KEKS_FN -X GET  https://$UNIFI_HOST:8443/api/s/default/stat/alluser"
PROVISION_CMD="curl  -k -b $KEKS_FN -X POST https://$UNIFI_HOST:8443/api/s/default/cmd/devmgr --data-binary '{\"mac\":\"f0:9f:c2:11:6b:ef\",\"cmd\":\"force-provision\"}' --insecure"


function login {
  login_result=$(eval $LOGIN_CMD)
  ok=$(echo "$login_result" | jq -r .meta.rc)
  if [ "$ok" == "ok"  ]; then
    echo "INFO: Login was successful."
  else
    echo "ERROR: Login failed. Exiting."
    exit -2
  fi
}

function fetch {
  rm -f $STAT_RESULT_FN

  echo "INFO: Trying to fetch stat from unifi controller."
  stat_result=$(eval $STAT_CMD)
  ok=$(echo "$stat_result" | jq -r .meta.rc)
  if [ ! "$ok" == "ok"  ]; then
    echo "INFO: The first try to fetch stat did not work so I log in to get a new cookie."
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


if [ ! -e $KEKS_FN ]; then
  echo "INFO: There is no cookie, so I login to the controller to create one." 
  login
else
  echo "INFO: There is a cookie, so I do not need to login to the controller to create one." 
fi

fetch 


###########################################
# Get the additional DNS entries via curl #
###########################################
# Download the file additional-manual-dns.json from github via curl and overwrite the local one with it.
# This way the container that this script goes into can run forever, you only have to edit the file 
# https://github.com/sejnub/unifi-tools/blob/master/add-dns/additional-manual-dns.json and then run the script again.

GET_ADDITIONAL_ENTRIES_CMD="curl -k $ADDITIONAL_ENTRIES_URL"

addentries_result=$(eval $GET_ADDITIONAL_ENTRIES_CMD) 

# Test if it is valid json
echo "< $addentries_result >"
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
  echo "INFO: Copying the resulting file to 'config.gateway.json' on the host $UNIFI_HOST."
  # -q = quiet (remove this option to identify problems)
  sshpass -p "$UNIFI_PASSWD" scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $ADD_DNS_RESULT_FN $UNIFI_USERNAME@$UNIFI_HOST:/srv/unifi/data/sites/default/config.gateway.json

  echo "INFO: Now you should manually force a provisioning on the usg via the unifi controller. Try <a href='https://192.168.1.30:8443/manage/site/default/devices/1/200'>add-dns.sh</a>"
  echo " "
  echo "================"
  echo "=== Success ===="
  echo "================"

  ##########################
  # WIP: Provision the usg #
  ##########################
  #provision_result=$(eval $PROVISION_CMD)
  #ok=$(echo "$provision_result" | jq -r .meta.rc)
  #if [ ! "$ok" == "ok"  ]; then
  #  echo ERROR: Provision did not work.
  #else
  #  echo INFO: Provision was successful.
  #fi  

else 
  echo "ERROR: There is no file with stat results so there is nothing to parse. This line should never be reached. Fix the script!"
fi





#eof
