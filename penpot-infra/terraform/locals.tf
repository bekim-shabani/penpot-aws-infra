locals {
  tags = {
    Project   = "penpotproject"
    ManagedBy = "terraform"
  }
  public_subnet  = aws_subnet.public_subnets[0].id
  private_subnet_1 = aws_subnet.private_subnets[0].id
  private_subnet_2 = aws_subnet.private_subnets[1].id
  vpc_id           = aws_vpc.main.id
}


