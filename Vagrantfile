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
  jointoken = {"JOINTOKEN" => "-"}

# ***************** Define UCP machine @ 192.168.33.10 ***********************
config.vm.define "ucp", primary: true do |ucp|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  ucp.vm.network "private_network", ip: "192.168.33.10"
  ucp.vm.hostname = "ucp"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  #ucp.vm.network "forwarded_port", guest: 4443, host: 8080

  ucp.vm.provision "shell" do |s| 
    puts "Provisioning UCP"
    puts "jointoken: #{jointoken}"
    s.env = jointoken
    puts "s.env: #{s.env}"
    s.inline = <<-SHELL
      apt-get update && apt-get upgrade -y
      apt-get install -y curl
      curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
      apt-get update && apt-get -y install apt-transport-https
      apt-get install -y linux-image-extra-virtual
      echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
      apt-get update && apt-get install -y docker-engine
      usermod -a -G docker ubuntu
      echo "Now installing UCP"
      docker run --rm --tty --name ucp -p 8080:80 -p 4443:443 -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address 192.168.33.10 --admin-username 'moby' --admin-password 'd!ck1234'
      echo "JoinToken: $JOINTOKEN"
      export JOINTOKEN=`docker swarm join-token -q worker`
      echo "JoinToken: $JOINTOKEN"
    SHELL
  end
  puts "After provisioning UCP"
  end

puts "Provisioning DTR with jointoken: #{jointoken}"
# ***************** Define DTR0 machine @ 192.168.33.20 ***********************
(0..1).each do |i|
  config.vm.define "dtr#{i}" do |dtr|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072"
  end
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  dtr.vm.network "private_network", ip: "192.168.33.2#{i}"
  dtr.vm.hostname = "dtr#{i}"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  #dtr.vm.network "forwarded_port", guest: 80, host: 8090

  dtr.vm.provision "shell", inline: <<-SHELL
      apt-get update && apt-get upgrade -y
      apt-get install -y curl
      curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
      apt-get update && apt-get -y install apt-transport-https
      apt-get install -y linux-image-extra-virtual
      echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
      apt-get update && apt-get install -y docker-engine
      usermod -a -G docker ubuntu
      echo "Joning UCP cluster"

      echo "Now installing DTR"
      docker run --rm --tty --name dtr -p 80:80 -p 443:443 -v /var/run/docker.sock:/var/run/docker.sock docker/dtr install --ucp-url https://192.168.33.10 --dtr-external-url https://192.168.33.2#{i}  --ucp-node dtr#{i} --ucp-username 'moby' --ucp-password 'd!ck1234' --ucp-insecure-tls
    SHELL
  end
  end

  
# ***************** Define Worker node ***********************
  config.vm.define "worker" do |worker|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  worker.vm.network "private_network", ip: "192.168.33.30"

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
    SHELL
  end
end
