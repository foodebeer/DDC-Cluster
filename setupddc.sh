#!/bin/bash
# DDC set up with Docker Machine
echo Test $0 $1 $2 $3
if [ $1 == "" ]; then
	echo "Usage setup.sh <number of UCP nodes> <number of DTR nodes> <number of worker node>"
	exit 1
fi
UCP_CNT=${1:-0}
DTR_CNT=${2:-0}
WORKER_CNT=${3:-0}

#### Images used
DTR_IMG=docker/dtr
DTR_TAG=2.3.3
DTR_SHA=6132eb90649dd8b2f7a2dcfe6385f712f2fd8990d7b848cd38d4e078fc33bc4c


if [[ ${UCP_CNT} == 0 ]]; then
    echo "0 UCP nodes"
fi
if [[ ${DTR_CNT} == 0 ]]; then
    echo "0 DTR nodes"
fi
if [[ ${WORKER_CNT} == 0 ]]; then
    echo "0 worker nodes"
fi

if [ "$UCP_ADMIN" == "" ]; then
	UCP_ADMIN="moby"
fi

if [ "$UCP_PASSWORD" == "" ]; then
	UCP_PASSWORD="d!ck1234"
fi

if [ "$ENVWORKERLABEL" == "" ]; then
	ENVWORKERLABEL="Test"
fi
if [ "$UCPVERSION" == "" ]; then
	UCPVERSION="2.1.5"
fi
if [ "$DTRVERSION" == "" ]; then
	DTRVERSION="2.2.7"
fi



#echo "Using $UCP_ADMIN and $UCP_PASSWORD"
UCP_EXISTS=$(docker-machine ls -q | grep -i ucp)
echo $UCP_EXISTS
if [ ${UCP_CNT} == 0 ]; then
	echo "No UCP nodes specified, assuming existing UCP cluster"
    if [[ "X${UCP_EXISTS}" == "X" ]]; then
        echo "No existing UCP nodes specified, I need them so exiting"
        exit -1
    fi
else
    echo "Creating UCP cluster"
    # Set up UCP HA
    echo "******************** Creating UCP cluster"
    docker-machine create -d virtualbox --virtualbox-memory "4096" ucp0 && docker-machine ssh ucp0 docker swarm init --advertise-addr $(docker-machine ip ucp0)
    echo "Swarm manager created"

    echo "Creating manager nodes"
    for (( COUNT=1; COUNT \< ${UCP_CNT}; COUNT++))
    do
        echo "Creating UCP node $COUNT"
        docker-machine create -d virtualbox --virtualbox-memory "4096" ucp$COUNT && docker-machine ssh ucp$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q manager) $(docker-machine ip ucp0)
    done
    echo "----------- Installing UCP ------------------"
    docker-machine ssh ucp0 docker run --rm --tty --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:$UCPVERSION install --host-address $(docker-machine ip ucp0) --admin-username "${UCP_ADMIN}" --admin-password "${UCP_PASSWORD}" --swarm-port 2378 --controller-port 9443

    echo "Create vizualiser"
    docker-machine ssh ucp0 docker service create --name=viz --publish=8082:8080/tcp --constraint=node.role==manager --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock dockersamples/visualizer

    echo "Create minio S3 compatible file storage"
    docker-machine ssh ucp0 docker service create --name=minio --no-healthcheck -e MINIO_ACCESS_KEY=minio -e MINIO_SECRET_KEY=miniostorage -p 9000:9000 minio/minio server /export
fi

if [ $3 == 0 ]; then
	echo "No worker nodes specified, skipping"
else
    # Worker nodes
    echo "***************** Creating and joining ${WORKER_CNT} $ENVWORKERLABEL worker nodes to Swarm cluster"
    rm swarmnodes
    #COUNT = 0
    for (( COUNT=0; COUNT < ${WORKER_CNT}; COUNT++))
    do
        echo "Creating node$COUNT"
        docker-machine create -d virtualbox --engine-label environment=$ENVWORKERLABEL node$COUNT  && echo "Created node$COUNT" && echo node$COUNT >> swarmnodes && docker-machine ssh node$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
    done
fi

if [ ${DTR_CNT} == 0 ]; then
	echo "No DTR nodes specified"

    echo "All done! You now have a working DDC cluster. You can access UCP at https://$(docker-machine ip ucp0):9443, and the Visualiser at http://$(docker-machine ip ucp0):8082"
	exit 1
else
    echo "***************** Create DTR cluster"
    echo "----------- Creating first DTR node ----------"
    docker-machine create -d virtualbox --virtualbox-memory "3072" dtr0
    # Join Swarm
    echo "----------- DTR joining Swarm ---------"
    docker-machine ssh dtr0 docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
    echo "--------------- Pulling DTR image-----------"
    # Download dtr image
		for SUB_IMG in api garant jobrunner nginx notary-server notary-signer postgres registry rethink;do
			echo "Downloading docker/dtr-${SUB_IMG}:${DTR_TAG}"
			docker-machine ssh dtr0 docker pull docker/dtr-${SUB_IMG}:${DTR_TAG}
		done
    echo "--------------- Installing DTR -----------"
    # Install DTR
    # Added 20170612 Well crap, it seems that docker login doesn't accept a port number at the moment, so I'll install DTR at the default port 443 (HTTPS)
    docker-machine ssh dtr0 docker run --rm --tty --name dtr docker/dtr install --debug --ucp-url https://$(docker-machine ip ucp0):9443 --dtr-external-url https://$(docker-machine ip dtr0)/ --ucp-node dtr0 --ucp-username "${UCP_ADMIN}" --ucp-password "${UCP_PASSWORD}" --ucp-insecure-tls --replica-id AB0000000000
    # Copy-paste from UCP for reference
    # docker run -it --rm docker/dtr install --dtr-external-url https://192.168.99.103/ --ucp-node dtr0 --ucp-username moby --ucp-insecure-tls --ucp-url https://192.168.99.100:9443

    echo "--------------- Installing DTR nodes -------------"
    for (( COUNT=1; COUNT \< ${DTR_CNT}; COUNT++))
    do
        echo "Create DTR node $COUNT"
        docker-machine create -d virtualbox --virtualbox-memory "3072" dtr$COUNT && docker-machine ssh dtr$COUNT docker swarm join --token $(docker-machine ssh ucp0 docker swarm join-token -q worker) $(docker-machine ip ucp0)
        #docker-machine ssh dtr$COUNT docker run --rm --tty -p 809$COUNT:80 844$COUNT:443 docker/dtr join --debug --ucp-node dtr$COUNT --ucp-insecure-tls --ucp-url https://$(docker-machine ip ucp0) --ucp-username $UCP_ADMIN --ucp-password $UCP_PASSWORD --existing-replica-id 1234567890AB --replica-http-port "809$COUNT" --replica-https-port "844$COUNT" --replica-id AB000000000$COUNT
        docker-machine ssh ucp0 docker run --rm --tty -p 809$COUNT:80 844$COUNT:443 docker/dtr join --debug --ucp-node dtr$COUNT --ucp-insecure-tls --ucp-url https://$(docker-machine ip ucp0):9443 --ucp-username "${UCP_ADMIN}" --ucp-password "${UCP_PASSWORD}" --existing-replica-id 1234567890AB --replica-http-port "809$COUNT" --replica-https-port "44$COUNT" --replica-id AB000000000$COUNT
    done

    if [ $? -ne 0 ]; then
        echo "Something went wrong"
        exit $?
    else
        echo "All done! You now have a working DDC cluster. You can access UCP at https://$(docker-machine ip ucp0):9443, and DTR at https://$(docker-machine ip dtr0):443 and the Visualiser at http://$(docker-machine ip ucp0):8082"
				echo "   >> Minio (s3 compatible storage backend), can be accessed at  http://$(docker-machine ip ucp0):9000 (ACCESS_KEY=minio / SECURE_KEY=miniostorage)"
    fi
fi
