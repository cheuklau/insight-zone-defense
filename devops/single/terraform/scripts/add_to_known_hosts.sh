##############################################
#
# Taken from https://github.com/InsightDataScience/pegasus/blob/master/config/ssh/add_to_known_hosts.sh
# Run on Master node.
#
##############################################

NAMENODE_DNS=$1; shift       # This is the Master DNS in the form ec2-xx-xxx-xx-xx.us-west-2.compute.amazonaws.com
NAMENODE_HOSTNAME=$1; shift
DATANODE_HOSTNAMES="$@"      # This is the list of Slave hostnames in the form IP-xx-xx-xx

# add NameNode to known_hosts
ssh-keyscan -H -t ecdsa $NAMENODE_DNS >> ~/.ssh/known_hosts

# add DataNodes to known_hosts
for hostname in ${DATANODE_HOSTNAMES}; do
    echo "Adding $hostname to known hosts..."
    ssh-keyscan -H -t ecdsa ${hostname%%.*} >> ~/.ssh/known_hosts
done

# add Secondary NameNode to known_hosts
ssh-keyscan -H -t ecdsa 0.0.0.0 >> ~/.ssh/known_hosts

# add localhost and 127.0.0.1 to known_hosts
ssh-keyscan -H -t ecdsa localhost >> ~/.ssh/known_hosts
ssh-keyscan -H -t ecdsa 127.0.0.1 >> ~/.ssh/known_hosts
