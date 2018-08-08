#!/bin/bash

# Update package manager and get tree package
sudo apt-get update
sudo apt-get install -y tree

# Setup a download and installation directory
HOME_DIR='/home/ubuntu'
INSTALLATION_DIR='/usr/local'
sudo mkdir ${HOME_DIR}/Downloads

# Install Java Development Kit
sudo apt-get install -y openjdk-8-jdk

# Install Python and Boto
sudo apt-get install -y python-pip python-dev build-essential
sudo pip install boto
sudo pip install boto3

# Install Flask
sudo pip install flask

# Install dependencies
sudo pip install googlemaps
sudo pip install flask_sqlalchemy
sudo pip install configparser
sudo pip install psycopg2

# Install gunicorn
sudo pip install gunicorn

# Install Git and clone repository
sudo apt-get install git-core
git clone https://github.com/cheuklau/insight_devops_airaware.git
