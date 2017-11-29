#!/bin/bash
USERNAME=x
PASSWD=x
UNIFY_HOST=wz
KEKS=/tmp/unify_cookie.txt
LOGIN_CMD="curl -s -d '{\"username\":\"$USERNAME\",\"password\":\"$PASSWD\",\"remember\":false,\"strict\":true}' -c $KEKS -k -X POST https://$UNIFY_HOST:8443/api/login"
STAT_CMD="curl -s -b $KEKS -k -X GET https://$UNIFY_HOST:8443/api/s/default/stat/sta"

function login {
 login_result=$(eval $LOGIN_CMD)
 ok=$(echo "$login_result" | jq -r .meta.rc)
 if [ "$ok" == "ok"  ]; then
  :
#   echo "login ok"
 else
   echo "login failed"
 fi
}

function fetch {
  stat_result=$(eval $STAT_CMD)
  ok=$(echo "$stat_result" | jq -r .meta.rc)
  if [ ! "$ok" == "ok"  ]; then
    login
    stat_result=$(eval $STAT_CMD)
    ok=$(echo "$stat_result" | jq -r .meta.rc)
    if [ ! "$ok" == "ok"  ]; then
     echo "ERROR!"
     exit -2
    fi
  fi
#  line_raw=$(echo "$stat_result" | \
#     jq -r '.data | .[] | "unifi_clients,hostname="+.hostname+",name="+.name+"XYXYrx="+(.rx_bytes|tostring)+",tx="+(.tx_bytes|tostring)')
#  echo $line_raw
#  line=$(echo "$line_raw" | sed -e 's/ /\\ /g' | sed  -e 's/XYXY/ /g' )
#  echo "$line"

  echo "$stat_result" | jq .data
}


if [ ! -e $KEKS ]; then
  login
fi

fetch


# curl -s -d '{"username":"x","password":"x","remember":false,"strict":true}' -c keks.txt -k -X POST https://wz:8443/api/login > /dev/null
# curl -s -b keks.txt -k -X GET https://wz:8443/api/s/default/stat/sta | jq -r '.data | .[] | "unifi_clients,hostname=\""+.hostname+"\",name=\""+.name+"\"
#  rx="+(.rx_bytes|tostring)+",tx="+(.tx_bytes|tostring)'
