# DDC-Cluster
This project contains files to set up and test a Docker DataCenter cluster.

The Vagrantfile defines 3 VMs:
- UCP: A VM with Docker UCP installed
- DTR: A VM with Docker Trusted Registry installed
- worker: a worker node that is joined to the UCP cluster.

The Vagrantfile will be extended with 2 additional UCP nodes to experiemnt with failover and restoring from backups.
The cluster will be used to deploy a 3-tier application.


