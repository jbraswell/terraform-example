provider "aws" {
}

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  tags {
    Name = "micah"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "192.168.0.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "micah"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "micah"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route" "mdc_public_subnet_to_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }
}

resource "aws_instance" "micah" {
  ami                    = "${data.aws_ami.amazon_linux.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.micah.id}"]
  subnet_id              = "${aws_subnet.public.id}"
  key_name               = "${aws_key_pair.micah.key_name}"

  associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash
yum install -y jq git
pip install yq
wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip -O terraform.zip
unzip terraform.zip
mv terraform /usr/local/bin/terraform
rm -f terraform.zip
EOF

  root_block_device {
    volume_size = 100
  }

  tags {
    Name = "micah"
  }
}

resource "aws_security_group" "micah" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "micah"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "micah" {
  key_name   = "jonathan-key-pair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

output "micah_ip" {
  value = "${aws_instance.micah.public_ip}"
}
