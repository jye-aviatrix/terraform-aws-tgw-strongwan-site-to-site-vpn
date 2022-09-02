# Add 10/8 route to region1 VPC private route tables
resource "aws_route" "region1_public" {
  for_each = toset(flatten([for k, v in var.cloud_vpcs_region1 : concat(module.cloud_vpc_region1[k].public_route_table_ids)]))

  route_table_id         = each.key
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region1.id

  timeouts {
    create = "5m"
  }
}

# Add 0/0 route to region1 VPC private route tables
resource "aws_route" "region1_private" {
  for_each = toset(flatten([for k, v in var.cloud_vpcs_region1 : concat(module.cloud_vpc_region1[k].private_route_table_ids)]))

  route_table_id         = each.key
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region1.id

  timeouts {
    create = "5m"
  }
}


# # Add 10/8 to Region1 OnPrem Public route tables, point to the StrongWAN gateway
resource "aws_route" "region1_public_vpn_gw" {
  for_each               = toset(module.onprem_vpc_region1.public_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = aws_cloudformation_stack.region1_vpn_gateway.outputs.NicID
}


# # Add 0/0 to Region1 OnPrem private route tables, point to the StrongWAN gateway
resource "aws_route" "region1_private_vpn_gw" {
  for_each               = toset(module.onprem_vpc_region1.private_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_cloudformation_stack.region1_vpn_gateway.outputs.NicID
}



# Add 10/8 route to region2 VPC private route tables
resource "aws_route" "region2_public" {
  for_each = toset(flatten([for k, v in var.cloud_vpcs_region2 : concat(module.cloud_vpc_region2[k].public_route_table_ids)]))

  route_table_id         = each.key
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region2.id

  timeouts {
    create = "5m"
  }
  provider = aws.secondary
}

# Add 0/0 route to region2 VPC private route tables
resource "aws_route" "region2_private" {
  for_each = toset(flatten([for k, v in var.cloud_vpcs_region2 : concat(module.cloud_vpc_region2[k].private_route_table_ids)]))

  route_table_id         = each.key
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region2.id

  timeouts {
    create = "5m"
  }
  provider = aws.secondary
}


# Add 10/8 to Region2 OnPrem Public route tables, point to the StrongWAN gateway
resource "aws_route" "region2_public_vpn_gw" {
  for_each               = toset(module.onprem_vpc_region2.public_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = aws_cloudformation_stack.region2_vpn_gateway.outputs.NicID
  provider               = aws.secondary
}


# # Add 0/0 to Region2 OnPrem private route tables, point to the StrongWAN gateway
resource "aws_route" "region2_private_vpn_gw" {
  for_each               = toset(module.onprem_vpc_region2.private_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_cloudformation_stack.region2_vpn_gateway.outputs.NicID
  provider               = aws.secondary
}
