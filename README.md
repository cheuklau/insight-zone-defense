# Insight DevOps Project

This repository contains the required files and write-up for Cheuk Lau's summer 2018 Insight DevOps project.

## Table of Contents

1. [Introduction](README.md#introduction)
2. [Data Engineering Application](README.md#data-engineering-application)
	* Overview - AirAware
    * Data extraction
    * Data transformation
    * Data loading
3. [DevOps Pipeline](README.md#devops-pipeline)
    * Overview
    * Terraform
    * Packer
4. [Advanced DevOps: Multi-Pipeline Infrastructure](README.md#advanced-devops)
	* Simulation - Increase Users
	* Simulation - Pipeline Failure
5. [Build Instructions](README.md#build-instructions)
	* Prerequisites
    * Download Data into S3
    * Run Terraform and Packer
    * Monitor with Prometheus
    * Event simulation
6. [Conclusions](README.md#conclusions)
7. [References](README.md#references)

## Introduction

The first goal of this project is to develop a DevOps pipeline for an existing data engineering (DE) application. The DevOps pipeline will provision infrastructure as code (IaC) using Terraform and Packer and version control both the DE application and IaC using Git. We will also show the use of auto-scaling and elastic load balancers (ELBs) to handle increased traffic and the use of a multi-pipeline infrastructure to handle a downed availability zone (AZ). Prometheus will be used to monitor traffic and server status during both simulations.

## Data Engineering Application

### Overview - AirAware

The DE application that we will work with is called AirAware (https://github.com/agaiduk/AirAware). The goal of AirAware is to show the historical pollution level at arbitrary addresses within the United States. The following figure illustrates the data engineering pipeline that AirAware uses.

![Fig 1: Data engineering application pipeline](/images/AirAware_Flow.png)

### Data Extraction

The measurement data is available from EPA (https://aqs.epa.gov/aqsweb/airdata/download_files.html#Raw) for the years 1980 to 2017. The measurement data provides hourly pollutant levels at fixed stations throughout the United States. The amount of data for the years after 2000 is approximately 10GB/year. For the data extraction step, the data is downloaded into an Amazon Web Service (AWS) S3 storage bucket, then loaded into Spark for processing.

### Data Transformation

The data transformation step calculates the pollution level at 100,000 spatial points distributed throughout the United States such that any arbitrary address is at most 15 miles away from one of the grid points. The pollution level at each grid point is calculated by inverse-distance weighting of the measurement data at the fixed stations. Several additional metrics are also computed including monthly averages for further analysis. Note that to reduce computational costs, the distances between grid points and measurement stations were pre-computed.

### Data Loading

The processed data along with additional metrics from Spark are loaded into a PostgreSQL database. We also use the PostGIS extension in order to perform easier location-based search. The user interface is provided through a Flask application which allows the user to select an address and view the monthly-averaged data from PostgreSQL.

## DevOps Pipeline

### Overview

The DevOps pipeline will provision infrastructure as code (IaC) using Terraform and Packer and version control both the DE application and IaC using Git. The following figure illustrates the DevOps pipeline used for AirAware:

![Fig 2: DevOps pipeline for AirAware](/images/AirAware_DevOps_Flow.png)

The proposed DevOps pipeline is an example of an immutable infrastructure where once an instance is launched, it is never changed, only replaced. The benefits of an immutable infrastructure include more consistency and reliability in addition to a simpler, more predictable deployment process. It also eliminates issues with mutable infrastructures such as configuration drift which requires the implementation of a configuration management tool (e.g., Chef, Puppet).

### Terraform

Terraform is used to setup the virtual private cloud (VPC) and other security group settings. The following figure illustrates the VPC used for AirAware:

![Fig 3: Virtual private cloud for AirAware](/images/AirAware_VPC_Single.png)

The figure above shows two subnets: public and private. Flask uses the public subnet which is connected to the internet through the internet gateway. The remaining data pipeline components (i.e., Spark and PostgreSQL) reside in the private subnet since the outside internet should not have access to these components. In addition to setting up the VPC, Terraform also sets up the security groups which limit communication between components to specific ports. Terraform is also used to spin up the amazon machine images (AMIs) created by Packer and configures them as necessary.

### Packer

Packer is used to create the Amazon machine images (AMI) for each of the components (i.e., Flask, Spark and PostgreSQL) of the data engineering pipeline. The AMIs use a base Ubuntu image and installs the required software.

## Advanced DevOps: Multi-Pipeline Infrastructure

In the previous section, we developed a baseline DevOps pipeline using immutable AWS infrastructure. In this section, we explore the use of a multi-pipeline infrastructure across multiple availability zones. The following figure illustrates the multi-pipeline infrastructure for this project:

![Fig 4: Multi-cloud for AirAware using one spark cluster](/images/AirAware_VPC_Multi.png)

The above infrastructure creates two pipelines in the same region across two availability zones. A Spark cluster is only placed in one of the pipelines, and the output is passed into the other using VPC peering sharing. This reduces the cost of haivng to spin up multiple Spark clusters, and is acceptable since batch processing only occurs periodically, and therefore we are only concerned with the customer having access to the front-end and databases containing post-processed data. We also place an elastic load balancer (ELB) to redirect traffic across the two pipelines, and auto-scale the front-end application (Flask instances) according to the fluctuation in user demand.

### Scenario - Increase Users

TBD

### Scenario - Pipeline Failure

TBD

## Build Instructions

### Prerequisites

The following software must be installed into your local environment:

* Terraform
* Packer
* AWS command line interface (CLI)

Clone the repository:

`git clone https://github.com/cheuklau/insight_devops_airaware.git`

### Download Data into S3

Perform the following steps to download the EPA data into AWS S3:

* Go to AWS console and navigate to `s3` under resources.
* Create a new bucket called `epa-data`.
* Login to an EC2 Ubuntu instance and perform the following:
	* `sudo apt install python-minimal`
	* `sudo apt-install python3`
	* `curl -O https://bootstrap.pypa.io/get-pip.py`
	* `python get-pip.py --user`
	* `pip install awscli --upgrade --user`
	* `sudo apt install unzip`
	* `wget https://aqs.epa.gov/aqsweb/airdata/hourly_44201_****.zip` 
	* `unzip https://aqs.epa.gov/aqsweb/airdata/hourly_44201_****.zip`
	* `export AWS_ACCESS_KEY_ID=<insert AWS access key ID>`
	* `export AWS_SECRET_ACCESS_KEY=<insert AWS secret key>`
	* `aws s3 cp hourly_44201_****.csv s3://epa-data`

Repeat the above process for each year of interest. Note that `****` indicates the year.

### Run Terraform and Packer

TBD

### Monitor with Prometheus

TBD

### Event Simulation

TBD

## Conclusions

TBD

## References


