############################################################################
#
# Postgres instance
#
############################################################################
resource "aws_instance" "postgres" {
  ami = "${var.AMIS}"
  instance_type = "m4.large"
  key_name = "${var.KEY_NAME}"
  count = 1
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "postgres-${var.SUBNET_NUM}"
    Environment = "dev"
    Terraform = "true"
  } 
}
