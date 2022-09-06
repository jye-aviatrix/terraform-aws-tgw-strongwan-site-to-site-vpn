# Add 10/8 route to region1 VPC private route tables
resource "aws_route" "region1_public" {
  for_each = var.cloud_vpcs_region1

  route_table_id         = module.cloud_vpc_region1[each.key].public_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region1.id

  timeouts {
    create = "5m"
  }
}

# Add 0/0 route to region1 VPC private route tables
resource "aws_route" "region1_private_default_0" {
  for_each = var.cloud_vpcs_region1

  route_table_id         = module.cloud_vpc_region1[each.key].private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region1.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "region1_private_default_1" {
  for_each = var.cloud_vpcs_region1

  route_table_id         = module.cloud_vpc_region1[each.key].private_route_table_ids[1]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_region1.id

  timeouts {
    create = "5m"
  }
}



# # Add 10/8 to Region1 OnPrem Public route tables, point to the StrongWAN gateway
resource "aws_route" "region1_public_vpn_gw" {
  route_table_id         = module.onprem_vpc_region1.public_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = aws_cloudformation_stack.region1_vpn_gateway.outputs.NicID
}


# # Add 0/0 to Region1 OnPrem private route tables, point to the StrongWAN gateway
resource "aws_route" "region1_private_vpn_gw" {
  count = 2
  route_table_id         = module.onprem_vpc_region1.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_cloudformation_stack.region1_vpn_gateway.outputs.NicID
}