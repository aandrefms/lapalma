resource "aws_instance" "server" {
  ami                    = local.ubuntu_22_04_ami_id
  instance_type          = "t3a.large"
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = data.aws_subnets.public_subnets.ids[0]
  key_name               = aws_key_pair.key.key_name

  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  volume_tags = merge(var.default_tags, {
    Name = "${local.project_name}-server"
  })
  
  user_data = <<-EOF
  #!/bin/bash
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl start docker && sudo systemctl enable docker
  sudo ufw disable
  EOF

  tags = {
    Name = "${local.project_name}-server"
  }
}

resource "aws_instance" "node" {
  count                  = var.node_count
  ami                    = local.ubuntu_22_04_ami_id
  instance_type          = "t3a.large"
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = data.aws_subnets.public_subnets.ids[0]
  key_name               = aws_key_pair.key.key_name

  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  user_data = <<-EOF
  #!/bin/bash
  ufw disable
  EOF

  volume_tags = merge(var.default_tags, {
    Name = "lapalma-prod-node"
  })

  tags = {
    Name = "lapalma-prod-node"
  }
}

resource "aws_eip" "node" {
  count    = var.node_count
  instance = aws_instance.node[count.index].id
  vpc      = true
}
