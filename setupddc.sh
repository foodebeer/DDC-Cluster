#!/bin/bash
# DDC set up with Docker Machine
echo Test $0 $1 $2 $3
if [ "$1" == "" ]; then
	echo "Usage setup.sh <number of UCP nodes> <number of DTR nodes> <number of worker node>"
	exit 1
fi

# Set up UCP HA
echo "******************** Creating UCP cluster"
docker-machine create -d virtualbox --virtualbox-memory "4096" ucp0 && docker-machine ssh ucp0 docker swarm init --advertise-addr $(docker-machine ip ucp0)
echo "Swarm manager created"

echo "Creating manager nodes"
for (( COUNT=1; COUNT \< $1; COUNT++))
do
    echo "Creating UCP node $COUNT"
    docker-machine create -d virtualbox --virtualbox-memory "4096" ucp$COUNT && docker-machine ssh ucp$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q manager) $(docker-machine ip ucp0)
done
echo "----------- Installing UCP ------------------"
docker-machine ssh ucp0 docker run --rm --tty --name ucp -p 8080:80 -p 4443:443 -P -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address $(docker-machine ip ucp0) --admin-username 'moby' --admin-password 'd!ck1234' --swarm-port 2378

echo "Create vizualiser"
docker-machine ssh ucp0 docker service create \
  --name=viz \
  --publish=8082:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

  # Worker nodes
echo "***************** Creating and joining $3 ACC worker nodes to Swarm cluster"
rm swarmnodes
#COUNT = 0
for (( COUNT=0; COUNT < $3; COUNT++))
do
	echo "Creating node$COUNT"
	docker-machine create -d virtualbox --engine-label environment=TESTLABEL node$COUNT  && echo "Created node$COUNT" && echo node$COUNT >> swarmnodes && docker-machine ssh node$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
done

echo "***************** Create DTR cluster"
echo "----------- Creating first DTR node ----------"
docker-machine create -d virtualbox --virtualbox-memory "3072" dtr0
# Join Swarm
echo "----------- DTR joining Swarm ---------"
docker-machine ssh dtr0 docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
echo "--------------- Installing DTR -----------"
# Install DTR
#docker-machine ssh dtr0 docker run --rm --tty --name dtr -p 8081:80 -p 4444:443 -P -v /var/run/docker.sock:/var/run/docker.sock docker/dtr install --ucp-url https://$(docker-machine ip ucp0) --dtr-external-url https://$(docker-machine ip dtr0)  --ucp-node dtr0 --ucp-username 'moby' --ucp-password 'd!ck1234' --ucp-insecure-tls --replica-id 1234567890AB
docker-machine ssh dtr0 docker run --rm --tty --name dtr -p 8090:80 -p 8440:443 docker/dtr install --ucp-url https://$(docker-machine ip ucp0) --dtr-external-url https://$(docker-machine ip dtr0)  --ucp-node dtr0 --ucp-username 'moby' --ucp-password 'd!ck1234' --ucp-insecure-tls --replica-id AB0000000000

echo "--------------- Installing DTR nodes -------------"
for (( COUNT=1; COUNT \< $2; COUNT++))
do
    echo "Create DTR node $COUNT"
    docker-machine create -d virtualbox --virtualbox-memory "3072" dtr$COUNT && docker-machine ssh dtr$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
    docker-machine ssh dtr$COUNT docker run --rm --tty -p 809$COUNT:80 844$COUNT:443 docker/dtr join --ucp-node dtr$COUNT --ucp-insecure-tls --ucp-url https://$(docker-machine ip ucp0) --ucp-username 'moby' --ucp-password 'd!ck1234' --existing-replica-id 1234567890AB --replica-http-port "809$COUNT" --replica-https-port "844$COUNT" --replica-id AB000000000$COUNT
done



echo "All done you now have a working DDC cluster. You can access UCP at https://$(docker-machine ip ucp0), and DTR at https://$(docker-machine ip dtr0) and the Visualiser at http://$(docker-machine ip ucp0):8082"
