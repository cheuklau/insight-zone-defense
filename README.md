# Zone Defense

This repository contains the required files and write-up for Cheuk Lau's 2018 Insight DevOps project.

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
6. [Conclusion](README.md#conclusion)
7. [Future Work](README.md#future-work)
    * CI/CD with Jenkins
    * Configuration Management with Puppet
    * Docker + ECS/EKS Containerization for Flask
    * AWS RDS for Postgres
    * AWS EMR for Spark
    * System Design - Scaling Up

## Introduction

The goal of this project is to automate the deployment of an application onto AWS by writing infrastructure as code (IaC), and building a high-reliability infrastructure by using auto-scaling and building redundant pipelines across multiple availability zones. The DevOps pipeline will use Terraform and Packer for automatic deployment, and Git for version control. Prometheus and Grafana will be used to monitor the health and status across all servers. We demonstrate the robustness of our infrastructure by spiking the traffic and simulating an availability zone outage.

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

## Conclusion

In this project, we have automated the deployment of an application onto AWS using a high-reliability infrastructure. We used Terraform and Packer to automate deployment, added auto-scaling to our user-facing servers to handle changes in traffic, and built redundant pipelines across multiple availability zones for increased fault tolerance.

## Future Work

### CI/CD with Jenkins

The developer to customer pipeline is summarized below:
1. Developer
2. Build
3. Test
4. Release
5. Provision and Deploy
6. Customer
Terraform and Packer handles steps 4 (release) and 5 (provision and deploy). However, we still need a continuous integration/continuous deployment or delivery (CI/CD) tool (e.g., Jenkins) to handle steps 2 (build) and 3 (test), and to trigger Terraform and Packer to perform steps 4 and 5. CI/CD for AirAware using Jenkins is summarized below:
* Developer pushes code into the staging environment.
* Jenkins detects the change and automatically triggers:
    + Packer to build the AMI in the staging environment.
    + Terraform to spin up the AMI in the staging environment.
* Jenkins checks the build using unit tests e.g., server connectivity.
* If build is not green, developers are notified.
* If green, we can either perform automatic deployment into a production environment (continuous delivery) or wait for manual approval (continuous deployment).
Below are some more specific work items to incorporate Jenkins for CI/CD:
* Create separate staging and production environments that both use the same Terraform modules.
* Use Terraform to spin up an additional instance to run Jenkins.
* Create a Jenkinsfile with the following properties:
    + Routinely monitors for changes to AirAware repository in the staging environment.
    + Create a build stage which triggers Packer to build new AMIs in the staging environment.
    + Create a deploy-to-staging stage which triggers Terraform to spin up the new AMIs in the staging environment.
    + Create a testing stage for the new infrastructure in the staging environment.
    + Create a deploy-to-production stage which either happens automatically if testing stage passes or waits for manual approval.

### Configuration Management with Puppet

In this project, we used Packer to build AMIs pre-baked with required software and used Bash scripts through Terraform to configure newly spun-up instances. Using Bash scripts in this manner is undesirable for the following reasons:
* Requires expert knowledge of scripting language standards and style
* Increased complication when dealing with mixed operating systems (OS)
An alternative is to use a configuration management (CM) tool e.g., Puppet, which can achieve the same results without worrying about the underlying OS or Bash commands. Puppet uses a declarative domain specific language (DSL) which allows users to only have to specify the task rather than how to perform the task. The main goal of Puppet is to maintain a defined state configuration. For AirAware, we will use a master-agent setup where agent nodes check in with the master node to see if anything needs to be updated. Communication between master and agent nodes is summarized below:
* Agent sends the data about its state to puppet master (facts which include hostname, kernel details, IP address, etc)
* Master compiles a list of configurations to be performed on agent (catalog which includes upgrades, removals, file creation, etc)
* Agent receives catalog from master and executes its tasks
* Agent reports back to master after catalog tasks are complete
Below are some more specific work items to incorporate Puppet for CM:
* Create a Puppet manifest for Spark, Postgres and Flask configurations
    + Manifest is a collection of Puppet classes with resources written in Puppet DSL that define the desired state
* Install Puppet and agent setup in Packer-generated AMIs 
* Create an additional instance to run Puppet master
* Provision Puppet manifest on Puppet master
* Install Puppet on master node, and start the Puppet server
* Use Puppet node definitions to perform manifest classes to appropriate servers e.g., Flask class only to Flask servers etc

### Docker + ECS/EKS Containerization for Flask

In this project, we strictly used virtual machines (VMs) for each component of AirAware. Each VM runs a full copy of an operating system (OS) and virtual copies of all the hardware that the OS needs to run. An alternative to VMs are containers which require just enough of an OS to run a given application. Containers are MBs instead of GBs in size compared to VMs and take seconds rather than minutes to spin up. Flask is a good candidate for containerization as it requires low OS overhead and need to be quickly spun up and down based on user-demand. We can use Docker to containerize Flask. This is done by creating a DockerFile that performs many of the same tasks as Packer to create a Flask Docker image. Docker can be used in conjunction with AWS elastic container service (ECS) or AWS elastic Kubernetes service (EKS) for container orchestration, which defines the relationship between containers, how they auto-scale and how they connect with the internet. Note that ECS and EKS clusters can be built in Terraform using `aws_ecs_cluser` and `aws_eks_cluster` resources respectively. 

### AWS RDS for Postgres

Amazon relational database service (RDS) supports Postgres and performs the following tasks:
* Scale database compute and storage resource with no downtime
* Perform backups
* Patches software
* Multi-availability zone deployments
* Manages synchronous data replication across availability zones
Note that Terraform can create an `aws_rds_cluster` resource.

### AWS EMR for Spark

Amazon elastic map reduce (EMR) provides a Hadoop framework to run Spark and performs the following tasks:
* Installs and configures software
* Provisions nodes
* Sets up cluster
* Increase or decrease the number of instances with Autoscaling
* Use spot instance
Note that Terraform can create an `aws_emr_cluster` resource.

### System Design - Scaling Up

