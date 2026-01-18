resource "aws_key_pair" "deployer_key" {
  key_name   = "github-action-key"
  public_key = var.ssh_public_key # Github Action<-- SSH public key
}

resource "aws_instance" "web" {
  ami           = "ami-0c94855ba95c71c99"  # Amazon Linux 2 in us-east-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name

  tags = {
    Name = "GitHubActionEC2"
  }
}
