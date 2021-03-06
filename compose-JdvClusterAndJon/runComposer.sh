#!/bin/bash
CSTATE=$(docker inspect -f {{.State.Running}} docker-dns)

if  [ -z "$CSTATE" ];  then
  docker run --privileged --name docker-dns --hostname docker-dns -d -v /var/run/docker.sock:/docker.sock  phensley/docker-dns  --domain docker;
elif [! $CSTATE  ]; then
  docker start docker-dns
fi
CSTATE=$(docker inspect -f {{.State.Running}} docker-dns)
echo "Is docker-dns started ? $CSTATE"
if  ! $CSTATE  ;  then   exit 1; fi

_DNS_IP=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' docker-dns)
_DNS_IP_ESC="$(echo "$_DNS_IP" | sed 's/[^-A-Za-z0-9_]/\\&/g')"
sed -i -e "s/dns:.*/dns: $_DNS_IP_ESC /" ./docker-compose.yml

docker-compose up -d

echo 'Provisioning is done, adding host names !'
for container in dv-master dv-slave2 dv-slave1 httpd-server rhq-server ; do

  cstate=$(docker inspect -f {{.State.Running}} $container)
    if  [ -z "$cstate" ] || [ ! $cstate ]  ;  then   continue; fi
  c_ip=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' $container )
  sudo bash -c "echo $c_ip $container >> /etc/hosts"
done
echo Done!
