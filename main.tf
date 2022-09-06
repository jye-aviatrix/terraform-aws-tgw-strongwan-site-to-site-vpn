data "aws_region" "tgw_region2" {
  provider = aws.secondary
}

resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering" {
  peer_account_id         = aws_ec2_transit_gateway.tgw_region2.owner_id
  peer_region             = data.aws_region.tgw_region2.name
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw_region2.id
  transit_gateway_id      = aws_ec2_transit_gateway.tgw_region1.id

  tags = {
    Name = "region1-to-region2-peering"
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id

  tags = {
    Name = "region2-to-region1-peering"
  }
  provider = aws.secondary
}

# TGW peering doesn't propagate route across. Need static route in TGW.
# CloudWAN is supposed to overcome this limit.
resource "aws_ec2_transit_gateway_route" "region1_to_region2_cloud" {
  destination_cidr_block         = "10.200.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw_region1.association_default_route_table_id
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering
  ]
}

resource "aws_ec2_transit_gateway_route" "region1_to_region2_onprem" {
  destination_cidr_block         = "10.20.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw_region1.association_default_route_table_id
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering
  ]
}

resource "aws_ec2_transit_gateway_route" "region2_to_region1_cloud" {
  destination_cidr_block         = "10.100.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw_region2.association_default_route_table_id
  provider = aws.secondary
}

resource "aws_ec2_transit_gateway_route" "region2_to_region1_onprem" {
  destination_cidr_block         = "10.10.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw_region2.association_default_route_table_id
  provider = aws.secondary
}