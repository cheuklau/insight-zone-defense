########################################################################
# Set up AWS VPC, subnets, security groups
########################################################################
module "aws" {

  source = "./modules/aws"

  AWS_ACCESS_KEY = "${var.AWS_ACCESS_KEY}"
  AWS_SECRET_KEY = "${var.AWS_SECRET_KEY}"
  AWS_REGION = "${var.AWS_REGION}"
  PATH_TO_PUBLIC_KEY = "${var.PATH_TO_PUBLIC_KEY}"

}

########################################################################
# Set up Prometheus 
########################################################################
# us-west-2a
module "prometheus-1" {

  source = "./modules/prometheus"

  AMIS = "${lookup(var.AMIS, "ubuntu")}"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  SUBNET = "${module.aws.SUBNET_1}"
  SUBNET_NUM = "1"
  PATH_TO_PRIVATE_KEY = "${var.PATH_TO_PRIVATE_KEY}"
  AWS_ACCESS_KEY = "${var.AWS_ACCESS_KEY}"
  AWS_SECRET_KEY = "${var.AWS_SECRET_KEY}"
  AWS_REGION = "${var.AWS_REGION}"

}

# us-west-2b
module "prometheus-2" {

  source = "./modules/prometheus"

  AMIS = "${lookup(var.AMIS, "ubuntu")}"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  SUBNET = "${module.aws.SUBNET_2}"
  SUBNET_NUM = "2"
  PATH_TO_PRIVATE_KEY = "${var.PATH_TO_PRIVATE_KEY}"
  AWS_ACCESS_KEY = "${var.AWS_ACCESS_KEY}"
  AWS_SECRET_KEY = "${var.AWS_SECRET_KEY}"
  AWS_REGION = "${var.AWS_REGION}"

}

########################################################################
# Set up Postgres
#
# Future work: Investigate AWS relational database services (RDS)
#              Easy replication and instance replacement (vertical scaling)
########################################################################
# us-west-2a
module "postgres-1" {

  source = "./modules/postgres"

  AMIS = "${lookup(var.AMIS, "postgres")}"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  SUBNET = "${module.aws.SUBNET_1}"
  SUBNET_NUM = "1"

}

# us-west-2b
module "postgres-2" {

  source = "./modules/postgres"

  AMIS = "${lookup(var.AMIS, "postgres")}"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  SUBNET = "${module.aws.SUBNET_2}"
  SUBNET_NUM = "2"

}

########################################################################
# Set up Spark
#
# Future work: Set up Spark using EMR so we can spin up/down on demand
########################################################################
module "spark" {

  source = "./modules/spark"

  AMIS = "${lookup(var.AMIS, "spark")}"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  SUBNET = "${module.aws.SUBNET_1}"
  NUM_WORKERS = "${var.NUM_WORKERS}"
  PATH_TO_PRIVATE_KEY = "${var.PATH_TO_PRIVATE_KEY}"
  AWS_ACCESS_KEY = "${var.AWS_ACCESS_KEY}"
  AWS_SECRET_KEY = "${var.AWS_SECRET_KEY}"
  AWS_REGION = "${var.AWS_REGION}"
  POSTGRES_DNS_1 = "${module.postgres-1.PRIVATE_DNS}"
  POSTGRES_DNS_2 = "${module.postgres-2.PRIVATE_DNS}"

}

########################################################################
# Set up Elastic Load Balancer
########################################################################
module "elb" {

  source = "./modules/elb"

  SUBNET_1 = "${module.aws.SUBNET_1}"
  SUBNET_2 = "${module.aws.SUBNET_2}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"

}

########################################################################
# Set up Flask Auto-Scaling Group
########################################################################
# us-west-2a
module "flask-1" {

  source = "./modules/flask"

  AMIS = "${lookup(var.AMIS, "flask")}"
  SUBNET_NUM = "1"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  POSTGRES_DNS_1 = "${module.postgres-1.PRIVATE_DNS}"
  POSTGRES_DNS_2 = "${module.postgres-2.PRIVATE_DNS}"
  SPARK_DNS = "${module.spark.MASTER_PRIVATE_DNS}"
  SUBNET = "${module.aws.SUBNET_1}"
  ELB_NAME = "${module.elb.ELB_NAME}"

}

# us-west-2b
module "flask-2" {

  source = "./modules/flask"

  AMIS = "${lookup(var.AMIS, "flask")}"
  SUBNET_NUM = "2"
  KEY_NAME = "${module.aws.KEY_NAME}"
  SECURITY_GROUP_ID = "${module.aws.SECURITY_GROUP_ID}"
  POSTGRES_DNS_1 = "${module.postgres-1.PRIVATE_DNS}"
  POSTGRES_DNS_2 = "${module.postgres-2.PRIVATE_DNS}"
  SPARK_DNS = "${module.spark.MASTER_PRIVATE_DNS}"
  SUBNET = "${module.aws.SUBNET_2}"
  ELB_NAME = "${module.elb.ELB_NAME}"

}
