/*

vpc.tf

This file sets up the virtual private cloud.

*/

##############################################
# Single cloud VPC
##############################################

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/26"     # CIDR block for the VPC (required)
    instance_tenancy = "default"   # Instance runs on shared hardware
    enable_dns_support = "true"    # Amazon-provided DNS server enabled (default=true)
    enable_dns_hostnames = "true"  # Amazon-provided DNS hostnames enabled (default=false)
    enable_classiclink = "false"   # Do not allow EC2-classic instances (default=false)
    tags {
        Name = "main"
    }
}

##############################################
# Subnets
##############################################

# Public
resource "aws_subnet" "main-public" {
    vpc_id = "${aws_vpc.main.id}"     # Main VPC ID previously defined
    cidr_block = "10.0.0.0/28"        # CIDR block for this subnet
    map_public_ip_on_launch = "true"  # Set to true for public subnets
    availability_zone = "us-west-2a"  # Availability zone
    tags {
        Name = "main-public"
    }
}

/*
# Private
resource "aws_subnet" "main-private" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/28"
    map_public_ip_on_launch = "false" # Set to false for private subnets
    availability_zone = "us-west-2a"
    tags {
        Name = "main-private"
    }
}
*/

##############################################
# Internet GW
##############################################

resource "aws_internet_gateway" "main-gw" {
    vpc_id = "${aws_vpc.main.id}" # VPC ID previously defined
    tags {
        Name = "main"
    }
}

##############################################
# Route tables for public subnet
##############################################

resource "aws_route_table" "main-public" {
    vpc_id = "${aws_vpc.main.id}" # ID of VPC previously defined
    # Route all IP addresses through this internet gateway
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main-gw.id}"
    }
    tags {
        Name = "main-public"
    }
}

##############################################
# Route tables
##############################################

# Route to Public subnet
resource "aws_route_table_association" "main-public" {
    subnet_id = "${aws_subnet.main-public.id}"
    route_table_id = "${aws_route_table.main-public.id}"
}
