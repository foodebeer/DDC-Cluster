#!/bin/bash
# DDC set up with Docker Machine
echo Test $0 $1 $2 $3
if [ $1 == "" ]; then
	echo "Usage setupddc-setup.sh number of UCP nodes> <number of worker nodes>\nThis stage sets up a number of VMs. Consecutive stages install UCP and DTR"
	exit 1
fi
if [[ ${1:-0} == 0 ]]; then
    echo "0 UCP nodes"
fi
if [[ ${2:-0} == 0 ]]; then
    echo "0 worker nodes"
fi

#echo "Set up Service node first"
#docker-machine create -d virtualbox servicenode
#docker-machine ssh servicenode docker swarm init --advertise-addr $(docker-machine ip servicenode)

echo "Creating UCP cluster"
# Set up UCP HA
echo "******************** Creating UCP cluster"
docker-machine create -d virtualbox --virtualbox-memory "4096" ucp0 && docker-machine ssh ucp0 docker swarm init --advertise-addr $(docker-machine ip ucp0)  #&& docker-machine ssh servicenode sudo "echo "$(cat logdriverdefault.json)" > daemon.json" && docker-machine ssh servicenode sudo mv daemon.json /etc/docker/daemon.json && docker-machine ssh ucp0 sudo /etc/init.d/docker restart && docker-machine ssh ucp0 docker swarm init --advertise-addr $(docker-machine ip ucp0) 


#echo "First Swarm manager created"
##echo "Create vizualiser"
#docker-machine ssh ucp0 docker service create --detach=true --name=viz --publish=8082:8080/tcp --constraint=node.role==manager --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock manomarks/visualizer

echo "Creating manager nodes"
for (( COUNT=1; COUNT \< $1; COUNT++))
do
    echo "Creating UCP node $COUNT"
    docker-machine create -d virtualbox --virtualbox-memory "4096" ucp$COUNT # && docker-machine ssh ucp$COUNT sudo "echo "$(cat logdriverdefault.json)" > daemon.json" && docker-machine ssh ucp$COUNT sudo mv daemon.json /etc/docker/daemon.json && docker-machine ssh ucp$COUNT sudo /etc/init.d/docker restart
    docker-machine ssh ucp$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q manager) $(docker-machine ip ucp0)  

done


if [ $2 == 0 ]; then
	echo "No worker nodes specified, skipping"
else
    # Worker nodes
    echo "***************** Creating and joining $2 $ENVWORKERLABEL worker nodes to Swarm cluster"
    rm swarmnodes
    #COUNT = 0
    for (( COUNT=0; COUNT < $2; COUNT++))
    do
        echo "Creating node$COUNT"
        docker-machine create -d virtualbox --engine-label environment=$ENVWORKERLABEL node$COUNT # && echo "Created node$COUNT" && echo node$COUNT >> swarmnodes &&   && docker-machine ssh dtr0 sudo "echo "$(cat logdriverdefault.json)" > daemon.json" && docker-machine ssh dtr0 sudo mv daemon.json /etc/docker/daemon.json && docker-machine ssh dtr0 sudo /etc/init.d/docker restart
        if [ $? -ne 0 ]; then
            echo "Something went wrong"
            exit $?
        fi
        docker-machine ssh node$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
    done
fi

# ---------------


if [ $? -ne 0 ]; then
    echo "Something went wrong"
    exit $?
else
    echo "All done you now have a working Swarm cluster. Next step is to install UCP and DTR."
fi


