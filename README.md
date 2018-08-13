# Insight DevOps Project

This repository contains the required files and write-up for Cheuk Lau's summer 2018 Insight DevOps project.

## Table of Contents

1. [Introduction](README.md#introduction)
2. [Data Engineering Application](README.md#data-engineering-application)
	* Overview - AirAware
    * Data Extraction
    * Data Transformation
    * Data Loading
3. [DevOps Pipeline](README.md#devops-pipeline)
    * Overview
    * Terraform
    * Packer
    * Prometheus
4. [Advanced DevOps](README.md#advanced-devops)
	* Demo - Traffic Spike
	* Demo - Availability Zone Outage
5. [Build Instructions](README.md#build-instructions)
	* Prerequisites
    * Download Data into S3
    * Deploy using Terraform and Packer
    * Run Spark Jobs
    * Monitor with Prometheus
6. [Conclusions](README.md#conclusions)
7. [References](README.md#references)

## Introduction

The goal of this project is to automate deployment of an existing application by writing infrastructure as code (IaC) then improving the existing reliability of the infrastructure by auto-scaling user-facing servers and building redundant pipelines across multiple availability zones. The DevOps pipeline will use Terraform and Packer for automatic deployment, and version control both the application and IaC using Git. Prometheus with Grafana will be used to monitor the health and status across all servers. We demonstrate the robustness of our infrastructure by spiking the traffic and simulating an availability zone outage.

## Data Engineering Application

### Overview - AirAware

The application we will deploy is called AirAware (https://github.com/agaiduk/AirAware). The goal of AirAware is to show the historical pollution level at any address in the United States. The following figure illustrates the data pipeline that AirAware uses.

![Fig 1: Data engineering application pipeline](/images/AirAware_Flow.png)

### Data Extraction

The measurement data is available from EPA (https://aqs.epa.gov/aqsweb/airdata/download_files.html#Raw) for the years 1980 to 2017. The measurement data provides hourly pollutant levels at fixed stations throughout the United States. The amount of data for the years after 2000 is approximately 10GB/year. For the data extraction step, the data is downloaded into an Amazon Web Service (AWS) S3 storage bucket, then loaded into Spark for processing.

### Data Transformation

The data transformation step calculates the pollution level at 100,000 spatial points distributed throughout the United States such that any arbitrary address is at most 15 miles away from one of the grid points. The pollution level at each grid point is calculated by inverse-distance weighting of the measurement data at the fixed stations. Several additional metrics are also computed including monthly averages for further analysis. Note that to reduce computational costs, the distances between grid points and measurement stations were pre-computed.

### Data Loading

The processed data along with additional metrics from Spark are loaded into a PostgreSQL database. We also use the PostGIS extension in order to perform easier location-based search. The user interface is provided through a Flask application which allows the user to select an address and view the monthly-averaged data from PostgreSQL.

## DevOps Pipeline

### Overview

The DevOps pipeline will write infrastructure as code (IaC) using Terraform and Packer and version control the application and IaC using Git. The following figure illustrates the DevOps pipeline used for AirAware:

![Fig 2: DevOps pipeline for AirAware](/images/AirAware_DevOps_Flow.png)

The proposed DevOps pipeline is an example of an immutable infrastructure where once an instance is launched, it is never changed, only replaced. The benefits of an immutable infrastructure include more consistency and reliability in addition to a simpler, more predictable deployment process. It also eliminates issues with mutable infrastructures such as configuration drift which requires the implementation of a configuration management tool (e.g., Chef, Puppet).

### Terraform

Terraform is used to setup the virtual private cloud (VPC) and other security group settings. The following figure illustrates the VPC used for AirAware:

![Fig 3: Virtual private cloud for AirAware](/images/AirAware_VPC_Single.png)

The figure above shows two subnets: public and private. Flask uses the public subnet which is connected to the internet through the internet gateway. The remaining data pipeline components (i.e., Spark and PostgreSQL) reside in the private subnet since the outside internet should not have access to these components. In addition to setting up the VPC, Terraform also sets up the security groups which limit communication between components to specific ports. Terraform is also used to spin up the amazon machine images (AMIs) created by Packer and configures them accordingly.

### Packer

Packer is used to create the Amazon machine images (AMI) for each of the components (i.e., Flask, Spark and PostgreSQL) of the data engineering pipeline. The AMIs use a base Ubuntu image and installs the required software.

## Advanced DevOps

In this section, we explore the use of an auto-scaled multi-pipeline infrastructure across multiple availability zones. The following figure illustrates the proposed infrastructure for this project:

![Fig 4: Multi-cloud for AirAware using one spark cluster](/images/AirAware_VPC_Multi.png)

The above infrastructure creates separate pipelines across two availability zones. A Spark cluster is only placed in one of the pipelines. This reduces the cost of having to spin up multiple Spark clusters, and is acceptable since batch processing only occurs periodically, and therefore we are only concerned with the customer having access to the front-end and databases containing post-processed data. We also place an elastic load balancer (ELB) to redirect traffic across the two availability zones, and auto-scale the front-end application (Flask servers) according to the fluctuation in user demand.

### Demo - Traffic Spike

We use LocustIO to simulate 1000 users pinging our elastic load balancer (ELB) at a rate of 3 clicks per second. The figure below plots the CPU usage as a function of time for the two availability zones (us-west-2a and us-west-2b) throughout the simulation.

![Fig 5: Traffic spike results](/images/Traffic_Spike.png)

The results show the initial spike in CPU usage in both availability zones followed by automatic provisioning of servers to decrease CPU usage across all servers until they are all below the upper threshold. Once LocustIO is turned off, the CPU usage decreases to nearly zero across all servers and they begin to spin down one by one until only a single server remains. We can also see that the ELB fairly evenly distributed work between the availability zone (perhaps slight bias towards us-west-2b in this example) and between the servers within each availability zone (as evident by the nearly overlapping lines). The screencast of this demo can be found here (https://youtu.be/I6_M_wAIVqY).

### Demo - Availability Zone Outage

We use LocustIO to again simulate 1000 users pinging our ELB at a rate of 3 clicks per second. We shut off the ELB connection to one of the availability zones (us-west-2b) at approximately the peak CPU usage. The figure below plots the CPU usage as a function of time for the two availability zones throughout the simulation.

![Fig 6: Availability zone outage results](/images/Zone_Outage.png)

The results show the initial spike in CPU usage in both availability zones. The CPU usage in us-west-2b prompty falls to zero once its ELB connection is removed. Note that the CPU in us-west-2a plateaus at around 12 percent which is nearly double that of the previous example (7 percent). This makes sense since us-west-2a should be handling nearly double the traffic with us-west-2b disconnected from the ELB. It also takes 7 servers for the CPU load on each machine of us-west-2a to fall below the upper threshold. This is approximately the sum of the servers for both availability zones in the previous example (8 servers), which again makes sense since us-west-2a is now handling all of the traffic. After Locust is turned off, we see the number of servers in us-west-2a spin down to one. The screencast of this demo can be found here (https://youtu.be/SjjnE2ZPrtU).

## Build Instructions

### Prerequisites

The following software must be installed into your local environment:

* Terraform
* Packer
* AWS command line interface (CLI)

Clone the repository:

`git clone https://github.com/cheuklau/insight_devops_airaware.git`

### Download Data into S3

Perform the following steps to download the EPA data into AWS S3. First, create an S3 bucket called `epa-data` then perform the following:

* `wget https://aqs.epa.gov/aqsweb/airdata/hourly_44201_****.zip` 
* `unzip https://aqs.epa.gov/aqsweb/airdata/hourly_44201_****.zip`
* `export AWS_ACCESS_KEY_ID=<insert AWS access key ID>`
* `export AWS_SECRET_ACCESS_KEY=<insert AWS secret key>`
* `aws s3 cp hourly_44201_xxxx.csv s3://epa-data` where `xxxx` is the year of interest.
* `aws s3 cp hourly_88101_xxxx.csv s3://epa-data`

### Build Infrastructure using Terraform and Packer

* `cd insight_devops_airaware/devops/single` to build the single pipeline infrastructure or `insight_devops_airaware/devops/multi` to build the multi-pipeline infrastructure.
* `vi build.sh` and change the user inputs as needed.
* `./build.sh`

Running `build.sh` performs the following:

* Calls Packer to build the Spark, Postgres, and Flask AMIs.
* Calls Terraform to spin up Spark cluster, Spark controller, Postgresl, and Flask instances.

The AirAware front-end is now visible at `<Flask-IP>:8000` or `<ELB-DNS>` if using the multi-pipeline infrastructure. However, we first must run Spark jobs from the Spark controller in order for any data to be visible.

### Run Spark Jobs

Perform the following to submit Spark jobs:

* `ssh ubuntu@<Spark-Controller-IP> -i mykeypair`
* `cd insight_devops_airaware/AirAware/spark`
* `spark-submit raw_batch.py hourly_44201_xxxx` where `xxxx` is the year of interest.
* `spark-submit raw_batch.py hourly_88101_xxxx` where `xxxx` is the year of interest.

We can monitor the status of the Spark jobs at `<Spark-Master-IP>:8080`.

### Monitor with Prometheus

We can go to the Prometheus dashboard at `<Prometheus-IP>:9090` or the Grafana dashboard at `<Prometheus-IP>:3000`. Node Exporter is installed and runnin gon the Flask servers and the Prometheus server is continuously scraping them for data. Grafana is reading the data sent to Prometheus and displaying them in more elegant dashboards. A default dashboard has been provided in this repo to display the CPU usage as a function of time across the used availability zones.

## Conclusions

In this project, we have automated the deployment of an existing application onto a highly reliable infrastructure. We used Terraform and Packer to write our infrastructure as code, added auto-scaling to our user-facing servers to handle fluctuations in traffic, and built redundant pipelines across multiple availability zones for increased fault tolerance.