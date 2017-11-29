#!/bin/bash

# Prerequisites
# - The variables $UNIFI_USERNAME, $UNIFI_PASSWD and $UNIFI_HOST must be set.
echo '$UNIFI_HOST' = $UNIFI_HOST

KEKS_FN=/tmp/unifi_cookie.txt
STAT_RESULT_FN=/tmp/unifi-stat.json
ADD_DNS_RESULT_FN=/tmp/unifi-add-dns-result.json
LIST_CLIENTS_RESULT_FN=/tmp/unifi-list-clients-result#.json

LOGIN_CMD="curl -s -d '{\"username\":\"$UNIFI_USERNAME\",\"password\":\"$UNIFI_PASSWD\",\"remember\":false,\"strict\":true}' -c $KEKS_FN -k -X POST https://$UNIFI_HOST:8443/api/login"
STAT_CMD="curl -s -b $KEKS_FN -k -X GET https://$UNIFI_HOST:8443/api/s/default/stat/alluser"


function login {
  login_result=$(eval $LOGIN_CMD)
  ok=$(echo "$login_result" | jq -r .meta.rc)
  if [ "$ok" == "ok"  ]; then
    echo "login successful"
  else
    echo "login failed"
    exit -2
  fi
}

function fetch {
  rm -f $STAT_RESULT_FN

  stat_result=$(eval $STAT_CMD)
  ok=$(echo "$stat_result" | jq -r .meta.rc)
  if [ ! "$ok" == "ok"  ]; then
    login
    stat_result=$(eval $STAT_CMD)
    ok=$(echo "$stat_result" | jq -r .meta.rc)
    if [ ! "$ok" == "ok"  ]; then
      echo "ERROR fetching stat"
      exit -2
    fi
  fi

  echo "$stat_result" > $STAT_RESULT_FN
}


if [ ! -e $KEKS_FN ]; then
  login
fi

fetch 

if [ -e $STAT_RESULT_FN ]; then
  # echo "Filtering stat-result with jq"
  jq -f add-dns.jq      $STAT_RESULT_FN > $ADD_DNS_RESULT_FN
  #jq -f list-clients.jq $STAT_RESULT_FN > $LIST_CLIENTS_RESULT_#FN
fi

sshpass -p "$UNIFI_PASSWD" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $ADD_DNS_RESULT_FN $UNIFI_USERNAME@UNIFI_HOST:/srv/unifi/data/sites/default/config.gateway.json




#eof
