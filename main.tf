data "aws_region" "tgw_region2" {
  provider = aws.secondary
}

resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering" {
  peer_account_id         = aws_ec2_transit_gateway.tgw_region2.owner_id
  peer_region             = data.aws_region.tgw_region2.name
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw_region2.id
  transit_gateway_id      = aws_ec2_transit_gateway.tgw_region1.id

  tags = {
    Name = "TGW Peering Requestor"
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id

  tags = {
    Name = "Example cross-account attachment"
  }
  provider = aws.secondary
}