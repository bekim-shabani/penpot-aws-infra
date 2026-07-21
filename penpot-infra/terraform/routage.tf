# Route table publique

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = merge(local.tags, {
    Name = "${var.cluster_name}-public-rt"
  })
}


resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# ───────────────────────────────────────────────────────────

# Route table privée
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  # Pas de route 0.0.0.0/0 ici — fck-nat l'ajoute automatiquement
  # via update_route_tables = true
  tags = merge(local.tags, {
    Name = "${var.cluster_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# Il faut le nat pour que les nodes pull les images
# fck-nat — NAT économique (~$6/mois vs ~$35 NAT Gateway)
# Instance EC2 t4g.micro (type par défaut du module) dans subnet public
# Route automatiquement le trafic des subnets privés vers internet
# ============================================================

module "fck-nat" {
  source = "RaJiska/fck-nat/aws"

  name                 = "${var.cluster_name}-fck-nat"
  vpc_id               = aws_vpc.main.id
  subnet_id = aws_subnet.public_subnets[0].id
  # ha_mode              = true                 # Enables high-availability mode
  # eip_allocation_ids   = ["eipalloc-abc1234"] # Allocation ID of an existing EIP
  # use_cloudwatch_agent = true                 # Enables Cloudwatch agent and have metrics reported

  update_route_tables = true
  route_tables_ids = {
    private = aws_route_table.private.id
  }
  tags = local.tags

  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.private
 ]
}
