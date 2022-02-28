# 1. Setup Unifi

## 1. Controller

### 1.1. Install docker container ryansch (for Raspberry Pi)

- <https://github.com/ryansch/docker-unifi-rpi>
- <https://github.com/sejnub/unifi-tools>

#### 1.1.1. Log into the rpi running the unifi container

```bash
ssh rpi02
```

#### 1.1.2. Run

```bash
cd ~/unifi
docker-compose down
docker pull ryansch/unifi-rpi:latest

cd ~
rm -rf ~/unifi
mkdir  ~/unifi
mkdir  ~/unifi-to-backup
mkdir  ~/unifi-to-backup/backup
cd     ~/unifi
curl -O https://raw.githubusercontent.com/sejnub/unifi-tools/master/controller/docker-compose-rpi.yml
touch ~/unifi-to-backup/config.gateway.json
mv docker-compose-rpi.yml docker-compose.yml
docker-compose up -d
```

#### 1.1.3. Update

```bash
ssh rpi02

docker pull ryansch/unifi-rpi:latest
cd ~/unifi
docker-compose down
docker-compose up -d
```

After the ```compose up``` the container might take up to 7 minutes until it is reachable via HTTP. 

#### 1.1.4. Make backups available once if container is already running

```bash
mkdir                                                            ~/unifi-to-backup
docker cp unifi:/var/lib/unifi/sites/default/config.gateway.json ~/unifi-to-backup

mkdir                                 ~/unifi-to-backup
mkdir                                 ~/unifi-to-backup/backup
docker cp unifi:/var/lib/unifi/backup ~/unifi-to-backup
```

### 1.2. Install docker container jacobalberty (HB only tested this for x86)

- <https://hub.docker.com/r/jacobalberty/unifi>
- <https://github.com/jacobalberty/unifi-docker>

```bash
cd ~
rm -rf ~/unifi
mkdir -p ~/unifi/data
mkdir -p ~/unifi/log
cd ~/unifi
docker run -d --restart always --init -p 8080:8080 -p 8443:8443 -p 3478:3478/udp -p 10001:10001/udp -e TZ='Europe/Berlin' -v ~/unifi:/unifi --name unifi jacobalberty/unifi:stable

```

### 1.3. Swap controllers

Links

- [manually setting the controller address for a unifi ap](https://community.spiceworks.com/how_to/9692-manually-setting-the-controller-address-for-a-unifi-ap)

Procedure

- Start new container, e.g. jacobalberty
- Change unifi ip
  - Change at <https://github.com/sejnub/unifi-tools/blob/master/add-dns/additional-manual-dns.json>
  - update vie unifi web tool
- On old container start migration wizard <https://help.ubnt.com/hc/en-us/articles/115002869188-UniFi-Migrating-Sites-with-Site-Export-Wizard>
  - Follow the steps

- Stop the old controller
  - If it is the cloudkey there is a stop button in the cloudkey GUI at port 80 (not the controller GUI at port 8443)

## 2. Misc setup howtos

- <https://freetime.mikeconnelly.com/archives/6241>

## 3. Mesh network (wireless uplink)

### 3.1. UniFi-Feature-Guide-Wireless-Uplink

<https://help.ubnt.com/hc/en-us/articles/115002262328-UniFi-Feature-Guide-Wireless-Uplink>

Under Configuration > Wireless Uplink, make sure to check "Allow meshing to another access point" (available for current UniFi Controller versions). Do this before disconnecting the APs from ethernet.

IMPORTANT: This option should be enabled for all wireless access points and disabled for all wired ones.

## 4. DNS

### 4.1. Create dns entries

See

- [docker-lighttpd_rpi-alpine-with-scripts](https://github.com/sejnub/docker-lighttpd/tree/master/rpi-alpine-with-scripts)
- <https://github.com/sejnub/unifi-tools/blob/master/add-dns/additional-manual-dns.json>

### 4.2. Show all static DNS entries in usg

SSH into the usg, then

```bash
show configuration commands | grep "static-mapping" | grep "ip-address" | grep -o "static-mapping.*" | cut -f2- -d" "
```

then putting that in a google sheets and manipulating it from there using split data to columns

or

will output all reserved IPs in IP_ADDRESS,MAC_ADDRESS format sorted by IP

```bash
show configuration commands | grep "static-mapping" | grep "ip-address" | grep -o "static-mapping.*" | cut -f2- -d" " | awk '{print $3,$1;}' | sed s/\ /\,/g | sort  -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4
```
