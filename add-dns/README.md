- [1. Purpose](#1-purpose)
- [2. TODO](#2-todo)
- [3. Links](#3-links)
  - [3.1. Same tool](#31-same-tool)
  - [3.2. nginx container](#32-nginx-container)
  - [3.3. jq](#33-jq)
  - [3.4. json](#34-json)
  - [3.5. unifi DNS](#35-unifi-dns)
  - [3.6. unifi API](#36-unifi-api)
- [4. Usage](#4-usage)
  - [4.1. Prerequisites](#41-prerequisites)
  - [4.2. Run the script to add DNS](#42-run-the-script-to-add-dns)
  - [4.3. Have a look at the resulting json files](#43-have-a-look-at-the-resulting-json-files)
- [5. Target structure](#5-target-structure)

# Add DNS

## 1. Purpose

Add DNS entries for the clients aliases (set in the unifi Web UI) to the usg.

## 2. TODO

- Auf dem Controller ein reprovisioning auslösen. Hierzu kucken, was auf Netzwerk passiert, wenn ich in unifi-gui auf force provision klicke.
  
- Momentan ist die interne domain ".internal" fest in das jq eingetragen. Das internal ist aber nicht statisch, sondern müsste vom controller geholt werden (zB über ````/api/s/default/rest/networkconf````).

- Zusätzliche DNS-Einträge ohne ".internal" für die hosts erzeugen, die schon einen .internal-Eintrag haben, sei es von mir gesetzt oder durch den hostname.


## 3. Links

### 3.1. Same tool

- <https://gist.github.com/patrickfuller/08d3dffec086845d3a3249629677ffce>

### 3.2. nginx container

- [rpi-nginx/](https://hub.docker.com/r/wouterds/rpi-nginx/)
- [hub.docker.com search armhf+cgi](https://hub.docker.com/search/?isAutomated=0&isOfficial=0&page=1&pullCount=0&q=armhf+cgi)


### 3.3. jq

- [jq manual v1.4](https://stedolan.github.io/jq/manual/v1.4/)
- [jq manual v1.5](https://stedolan.github.io/jq/manual/v1.5/)
- [jq Cookbook](https://github.com/stedolan/jq/wiki/Cookbook)

- [jqplay.org](https://jqplay.org/)


### 3.4. json

- [jsoneditoronline.org](http://jsoneditoronline.org/)


### 3.5. unifi DNS

- https://community.ubnt.com/t5/EdgeMAX/Create-DNS-enteries/td-p/468375

- https://community.ubnt.com/t5/UniFi-Routing-Switching/Unifi-USG-manual-DNS-Record/td-p/1972796

- https://community.ubnt.com/t5/UniFi-Routing-Switching/Internal-DNS-on-USG/td-p/1592293/page/2


### 3.6. unifi API

- https://community.ubnt.com/t5/UniFi-Wireless/UniFi-API-browser-tool-updates-and-discussion/m-p/1392651/highlight/true#M128759

- https://community.ubnt.com/t5/UniFi-Wireless/api-err-Invalid-Error-When-Logging-In-To-Unifi-API-Via-curl/m-p/1676063/highlight/true#M181802

- https://community.ubnt.com/t5/UniFi-Wireless/Not-working-API/td-p/569949

- https://github.com/Art-of-WiFi/UniFi-API-browser


## 4. Usage

This script is meant to be called by https://github.com/sejnub/docker-lighttpd/tree/master/rpi-alpine-with-scripts.
But in the following sections it is described how to use it directly without the HTTP server.

### 4.1. Prerequisites

```bash
sudo apt-get install jq
sudo apt-get install sshpass
```

### 4.2. Run the script to add DNS
````
mkdir ~/hb-src; cd ~/hb-src; rm -rf unifi-tools/; 
git clone https://github.com/sejnub/unifi-tools.git
cd unifi-tools/add-dns
echo 

. ./init.sh

set -a
. /usr/local/etc/sejnub-credentials.env
set +a

./add-dns.sh


eof
````


### 4.3. Have a look at the resulting json files

````
cat /tmp/unifi-stat.json | jq .

cat /tmp/unifi-add-dns-result.json | jq .

cat /tmp/unifi-list-clients-result.json | jq .

eof
````


## 5. Target structure

````
{
        "system": {
                "static-host-mapping": {
                        "host-name": {
                                "myname.com": {
                                        "inet": [
                                                "192.168.1.4"
                                        ]
                                },
                               "myothername.com": {
                                        "inet": [
                                                "192.168.1.5"
                                        ]
                                }
                        }
                }
        }
}
````

eof
