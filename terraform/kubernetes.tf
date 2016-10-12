provider "aws" {
  access_key = "${var.access_key}"
  region     = "${var.region}"
  secret_key = "${var.secret_key}"
  token      = "${var.token}"
}

resource "aws_autoscaling_group" "master" {
  name                 = "master-${var.region}a.masters.${var.fqdn}"
  launch_configuration = "${aws_launch_configuration.master.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["${aws_subnet.a.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "${var.fqdn}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-${var.region}a.masters.${var.fqdn}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/dns/internal"
    value               = "api.internal.${var.fqdn}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/dns/public"
    value               = "api.${var.fqdn}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "nodes" {
  name                 = "nodes.${var.fqdn}"
  launch_configuration = "${aws_launch_configuration.nodes.id}"
  max_size             = "${var.nodes-max}"
  min_size             = "${var.nodes-min}"
  desired_capacity     = "${var.nodes-desired}"
  vpc_zone_identifier  = ["${aws_subnet.a.id}", "${aws_subnet.b.id}", "${aws_subnet.c.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "${var.fqdn}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "nodes.${var.fqdn}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }
}

resource "aws_ebs_volume" "etcd-events" {
  availability_zone = "${var.region}a"
  size              = 20
  type              = "gp2"
  encrypted         = false

  tags = {
    KubernetesCluster    = "${var.fqdn}"
    Name                 = "${var.region}a.etcd-events.${var.fqdn}"
    "k8s.io/etcd/events" = "${var.region}a/${var.region}a"
    "k8s.io/role/master" = "1"
  }
}

resource "aws_ebs_volume" "etcd-main" {
  availability_zone = "${var.region}a"
  size              = 20
  type              = "gp2"
  encrypted         = false

  tags = {
    KubernetesCluster    = "${var.fqdn}"
    Name                 = "${var.region}a.etcd-main.${var.fqdn}"
    "k8s.io/etcd/main"   = "${var.region}a/${var.region}a"
    "k8s.io/role/master" = "1"
  }
}

resource "aws_iam_instance_profile" "masters" {
  name  = "masters.${var.fqdn}"
  roles = ["${aws_iam_role.masters.name}"]
}

resource "aws_iam_instance_profile" "nodes" {
  name  = "nodes.${var.fqdn}"
  roles = ["${aws_iam_role.nodes.name}"]
}

resource "aws_iam_role" "masters" {
  name               = "masters.${var.fqdn}"
  assume_role_policy = "${file("data/aws_iam_role_masters_policy")}"
}

resource "aws_iam_role" "nodes" {
  name               = "nodes.${var.fqdn}"
  assume_role_policy = "${file("data/aws_iam_role_nodes_policy")}"
}

resource "aws_iam_role_policy" "masters" {
  name   = "masters.${var.fqdn}"
  role   = "${aws_iam_role.masters.name}"
  policy = "${data.template_file.masters-aws-iam-role-policy.rendered}"
}

data "template_file" "masters-aws-iam-role-policy" {
  template = "${file("data/aws_iam_role_policy_masters_policy")}"

  vars {
    fqdn             = "${var.fqdn}"
    kops-state-store = "${var.kops-state-store}"
  }
}

resource "aws_iam_role_policy" "nodes" {
  name   = "nodes.${var.fqdn}"
  role   = "${aws_iam_role.nodes.name}"
  policy = "${data.template_file.nodes-aws-iam-role-policy.rendered}"
}

data "template_file" "nodes-aws-iam-role-policy" {
  template = "${file("data/aws_iam_role_policy_nodes_policy")}"

  vars {
    fqdn             = "${var.fqdn}"
    kops-state-store = "${var.kops-state-store}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.fqdn}"
  }
}

resource "aws_key_pair" "kubernetes" {
  key_name   = "kubernetes.${var.fqdn}"
  public_key = "${var.ec2_pubkey}"
}

resource "aws_launch_configuration" "master" {
  name_prefix                 = "master-${var.region}a.masters.${var.fqdn}-"
  image_id                    = "${var.master-ami}"
  instance_type               = "${var.master-instance-type}"
  key_name                    = "${aws_key_pair.kubernetes.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters.id}"
  security_groups             = ["${aws_security_group.masters.id}"]
  associate_public_ip_address = true
  user_data                   = "${data.template_file.master-aws-launch-configuration-user-data.rendered}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = "${var.master-volume-size}"
    delete_on_termination = true
  }

  ephemeral_block_device = {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  lifecycle = {
    create_before_destroy = true
  }
}

data "template_file" "master-aws-launch-configuration-user-data" {
  template = "${file("data/aws_launch_configuration_master_user_data")}"

  vars {
    FQDN   = "${var.fqdn}"
    KOPS   = "${var.kops-state-store}"
    REGION = "${var.region}"
  }
}

resource "aws_launch_configuration" "nodes" {
  name_prefix                 = "nodes.${var.fqdn}-"
  image_id                    = "${var.nodes-ami}"
  instance_type               = "${var.nodes-instance-type}"
  key_name                    = "${aws_key_pair.kubernetes.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes.id}"
  security_groups             = ["${aws_security_group.nodes.id}"]
  associate_public_ip_address = true
  user_data                   = "${data.template_file.nodes-aws-launch-configuration-user-data.rendered}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = "${var.nodes-volume-size}"
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }
}

data "template_file" "nodes-aws-launch-configuration-user-data" {
  template = "${file("data/aws_launch_configuration_nodes_user_data")}"

  vars {
    FQDN = "${var.fqdn}"
    KOPS = "${var.kops-state-store}"
  }
}

resource "aws_route" "0-0-0-0--0" {
  route_table_id         = "${aws_route_table.main.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.fqdn}"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.a.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route_table_association" "b" {
  subnet_id      = "${aws_subnet.b.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route_table_association" "c" {
  subnet_id      = "${aws_subnet.c.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_security_group" "masters" {
  name        = "masters.${var.fqdn}"
  vpc_id      = "${aws_vpc.main.id}"
  description = "Security group for masters"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "masters.${var.fqdn}"
  }
}

resource "aws_security_group" "nodes" {
  name        = "nodes.${var.fqdn}"
  vpc_id      = "${aws_vpc.main.id}"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "nodes.${var.fqdn}"
  }
}

resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters.id}"
  source_security_group_id = "${aws_security_group.masters.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes.id}"
  source_security_group_id = "${aws_security_group.masters.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-node-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters.id}"
  source_security_group_id = "${aws_security_group.nodes.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes.id}"
  source_security_group_id = "${aws_security_group.nodes.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "https-external-to-master" {
  type              = "ingress"
  security_group_id = "${aws_security_group.masters.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh-external-to-master" {
  type              = "ingress"
  security_group_id = "${aws_security_group.masters.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh-external-to-node" {
  type              = "ingress"
  security_group_id = "${aws_security_group.nodes.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_subnet" "a" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "172.20.32.0/19"
  availability_zone = "${var.region}a"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.region}a.${var.fqdn}"
  }
}

resource "aws_subnet" "b" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "172.20.64.0/19"
  availability_zone = "${var.region}b"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.region}b.${var.fqdn}"
  }
}

resource "aws_subnet" "c" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "172.20.96.0/19"
  availability_zone = "${var.region}c"

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.region}c.${var.fqdn}"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.fqdn}"
  }
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    KubernetesCluster = "${var.fqdn}"
    Name              = "${var.fqdn}"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
}
