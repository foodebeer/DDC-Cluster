# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial64"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

config.vm.define "ucp", primary: true do |ucp|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072"
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  ucp.vm.network "private_network", ip: "192.168.33.10"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  ucp.vm.network "forwarded_port", guest: 8080, host: 8080

  ucp.vm.provision "shell", inline: <<-SHELL
      apt-get update && apt-get upgrade -y
      apt-get install -y curl
      curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
      apt-get update && apt-get -y install apt-transport-https
      apt-get install -y linux-image-extra-virtual
      echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
      apt-get update && apt-get install -y docker-engine
      usermod -a -G docker ubuntu
      echo "Now installing UCP"
      docker run --rm --tty --name ucp -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address 192.168.33.10 --admin-username 'moby' --admin-password 'd!ck1234'
    SHELL
  end

  config.vm.define "dtr", primary: true do |dtr|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072"
  end
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  dtr.vm.network "private_network", ip: "192.168.33.11"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  dtr.vm.network "forwarded_port", guest: 8080, host: 8090

  dtr.vm.provision "shell", inline: <<-SHELL
      apt-get update && apt-get upgrade -y
      apt-get install -y curl
      curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
      apt-get update && apt-get -y install apt-transport-https
      apt-get install -y linux-image-extra-virtual
      echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
      apt-get update && apt-get install -y docker-engine
      usermod -a -G docker ubuntu
      echo "Now installing DTR"
      docker run --rm -it --name dtr -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock docker/dtr install --ucp-url http://192.168.33.10:8080 --ucp-node ucp --dtr-external-ip 192.168.33.11  --ucp-username 'moby' --ucp-password 'd!ck1234' --ucp-insecure-tls
    SHELL
  end

  config.vm.define "worker", primary: true do |worker|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  worker.vm.network "private_network", ip: "192.168.33.12"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  worker.vm.network "forwarded_port", guest: 80, host: 8180

  worker.vm.provision "shell", inline: <<-SHELL
      apt-get update && apt-get upgrade -y
      apt-get install -y curl
      curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
      apt-get update && apt-get -y install apt-transport-https
      apt-get install -y linux-image-extra-virtual
      echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
      apt-get update && apt-get install -y docker-engine
      usermod -a -G docker ubuntu
      #docker run --rm -it --name ucp -p 80:80 -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address 192.168.33.10 --admin-username 'moby' --admin-password 'd!ck1234'
    SHELL
  end
end
