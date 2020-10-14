#!/bin/bash

# Directories
srcs=./srcs
dir_goinfre=/goinfre/$USER # /goinfre/$USER at 42 or /sgoinfre - /Users/$USER at home on Mac
docker_destination=$dir_goinfre/docker
dir_minikube=$dir_goinfre/minikube
dir_archive=$dir_goinfre/images-archives
volumes=$srcs/volumes

if [[ $1 == "install" ]]
then
		pre_config_start=`date +%s`
		# BREW
		which -s brew
		if [[ $? != 0 ]] ; then
			echo "Brew not installed, installling..."
			# Install brew
			rm -rf $HOME/.brew
			git clone --depth=1 https://github.com/Homebrew/brew $HOME/.brew
			echo 'export PATH=$HOME/.brew/bin:$PATH' >> $HOME/.zshrc
			source $HOME/.zshrc
		fi
		echo "Updating brew..."
		brew update > /dev/null

		# KUBECTL
		which -s kubectl
		if [[ $? != 0 ]] ; then
			echo "Kubectl not installed, installing..."
			# Install kubectl
			brew install kubectl
		fi

		# MINIKUBE
		which -s minikube
		if [[ $? != 0 ]] ; then
			echo "Minikube not installed, installing..."
			# Install minikube 
			brew install minikube
		fi
		mkdir -p $dir_minikube
		ln -sf $dir_minikube /Users/$USER/.minikube

		# DOCKER
		brew uninstall -f docker docker-compose
		if [ ! -d "/Applications/Docker.app" ] && [ ! -d "~/Applications/Docker.app" ]; then
			#echo $'\033[0;34m'Please install $'\033[1;96m'Docker for Mac $'\033[0;34m'from the MSC \(Managed Software Center\)$'\033[0;39m'
			#open -a "Managed Software Center"
			#read -p $'\033[0;34m'Press\ RETURN\ when\ you\ have\ successfully\ installed\ $'\033[1;96m'Docker\ for\ Mac$'\033[0;34m'...$'\033[0;39m'
			echo "Docker not installed, installing..."
			brew install docker
			#brew cask install docker
		fi
		pkill Docker
		if [ ! -d $docker_destination ]; then
			rm -rf ~/Library/Containers/com.docker.docker ~/.docker
			mkdir -p $docker_destination/{com.docker.docker,.docker}
			ln -sf $docker_destination/com.docker.docker ~/Library/Containers/com.docker.docker
			ln -sf $docker_destination/.docker ~/.docker
		fi
		
		# Check if docker is running
		docker_state=$(docker info >/dev/null 2>&1)
		if [[ $? -ne 0 ]]; then
			echo "Opening Docker..."
			open -g -a Docker > /dev/null
		fi

		# DOCKER-MACHINE
		which -s docker-machine
		if [[ $? != 0 ]] ; then
			echo "docker-machine not installed, installing..."
			# Install docker-machine
			brew install docker-machine
		fi

		echo "Deleting previous docker-machine and minikube..."
		# Stopping docker-machine & minikube if started
		docker-machine stop > /dev/null
		minikube delete

		# Launch docker-machine
		docker-machine create --driver virtualbox default > /dev/null
		docker-machine start

		# Launch Minikube
		minikube start --cpus=2 --disk-size 11000 --vm-driver virtualbox --extra-config=apiserver.service-node-port-range=1-35000
		minikube addons enable dashboard
		minikube addons enable ingress
		minikube addons enable metrics-server

		#If error
		#VBoxManage hostonlyif remove vboxnet1
	
		minikube ip > /tmp/.minikube.ip
		pre_config_end=`date +%s`	
		runtime=$((pre_config_end-pre_config_start))
		echo "Pre-config done - $runtime seconds)"
fi
