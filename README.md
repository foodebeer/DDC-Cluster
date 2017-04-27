# DDC-Cluster
This project contains files to set up and test a Docker DataCenter cluster.

setupddc.sh creates a Docker Swarm cluster with Docker Enterprise Edition Standard (Docker DataCenter).

Usage:
setupddc.sh <number of UCP managers> <number of DTR nodes> <number of worker nodes>

Don't forget to make the file executable with chmod +x setupddc.sh

Example:
setupddc.sh 1 1 2 will create a Swarm cluster with 1 manager running UCP, 1 worker node running DTR, and 2 worker nodes.

setupddc.sh will put 3 files in your working directory:
It creates 1 file in your working directory 'swarmnodes' which you can use to delete the Docker Machines you just created.

UCP admin name is set in environment variable UCP_ADMIN, if not set it is by default 'moby'.
UCP password is set in environment variable UCP_PASSWORD, if not set it is by default 'd!ck1234'.

Since DTR takes a loooooooong time to install, it frequently times out. You can get around this by running
  setupddc.sh 1 0 2 
then
  setupddc.sh 0 1 0
  
 

