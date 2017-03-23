# DDC-Cluster
This project contains files to set up and test a Docker DataCenter cluster.

setupddc.sh creates a Docker Swarm cluster with Docker Enterprise Edition Standadr (Docker DataCenter).

-- Old - doesn't really work, currently not in active development.
The Vagrantfile defines 3 VMs:
- UCP: A VM with Docker UCP installed
- DTR: A VM with Docker Trusted Registry installed
- worker: a worker node that is joined to the UCP cluster.

The Vagrantfile will be extended with 2 additional UCP nodes to experiment with failover and restoring from backups.
The cluster will be used to deploy a 3-tier application.


