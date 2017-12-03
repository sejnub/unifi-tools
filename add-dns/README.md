# TODO

- Auf dem Controller ein reprovisioning auslösen. Hierzu kucken, was auf Netzwerk passiert, wenn ich in unifi-gui auf force provision klicke.

- Zusätzliche manuelle DNS-Enträge implementieren

  - https://stackoverflow.com/questions/19529688/how-to-merge-2-json-file-using-jq  
  
- Momentan ist die interne domain ".internal" fest in das jq eingetragen. Das internal ist aber nicht statisch, sondern müsste vom controller geholt werden (zB über ````/api/s/default/rest/networkconf````).

- Zusätzliche DNS-Einträge ohne ".internal" für die hosts erzeugen, die schon einen .internal-Eintrag haben, sei es von mir gesetzt oder durch den hostname.


# Links

## nginx container

- [rpi-nginx/](https://hub.docker.com/r/wouterds/rpi-nginx/)
- [hub.docker.com search armhf+cgi](https://hub.docker.com/search/?isAutomated=0&isOfficial=0&page=1&pullCount=0&q=armhf+cgi)


## jq

- [jq manual v1.4](https://stedolan.github.io/jq/manual/v1.4/)
- [jq manual v1.5](https://stedolan.github.io/jq/manual/v1.5/)
- [jq Cookbook](https://github.com/stedolan/jq/wiki/Cookbook)

- [jqplay.org](https://jqplay.org/)


## json

- [jsoneditoronline.org](http://jsoneditoronline.org/)


## unifi DNS

- https://community.ubnt.com/t5/EdgeMAX/Create-DNS-enteries/td-p/468375

- https://community.ubnt.com/t5/UniFi-Routing-Switching/Unifi-USG-manual-DNS-Record/td-p/1972796

- https://community.ubnt.com/t5/UniFi-Routing-Switching/Internal-DNS-on-USG/td-p/1592293/page/2


## unifi API

- https://community.ubnt.com/t5/UniFi-Wireless/UniFi-API-browser-tool-updates-and-discussion/m-p/1392651/highlight/true#M128759

- https://community.ubnt.com/t5/UniFi-Wireless/api-err-Invalid-Error-When-Logging-In-To-Unifi-API-Via-curl/m-p/1676063/highlight/true#M181802

- https://community.ubnt.com/t5/UniFi-Wireless/Not-working-API/td-p/569949

- https://github.com/Art-of-WiFi/UniFi-API-browser


# Usage

## Run the script to add DNS
````
cd ~/hb-src; rm -rf unifi-tools/; git clone https://github.com/sejnub/unifi-tools.git; cd unifi-tools/add-dns; echo; 

. ./init.sh

set -a
. /usr/local/etc/sejnub-credentials.env
set +a

./add-dns.sh


eof
````


## Have a look at the resulting json files

````
cat /tmp/unifi-stat.json | jq .

cat /tmp/unifi-add-dns-result.json | jq .

cat /tmp/unifi-list-clients-result.json | jq .

eof
````


# Target structure

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
