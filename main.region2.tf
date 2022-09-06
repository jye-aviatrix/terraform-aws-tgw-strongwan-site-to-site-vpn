module "cloud_vpc_region2" {
  source = "./modules/aws_vpc"

  for_each = var.cloud_vpcs_region2
  name     = each.key
  cidr     = each.value

  azs                                = slice(data.aws_availability_zones.available_region2.names, 0, 2) # Select first two aws availability zones
  public_subnets                     = slice(cidrsubnets(each.value, 2, 2, 2, 2), 0, 2)                 # Caculate consecuitive CIDR range for public subnets
  private_subnets                    = slice(cidrsubnets(each.value, 2, 2, 2, 2), 2, 4)                 # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway                 = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw  = false
  providers = {
    aws = aws.secondary
  }
}

module "onprem_vpc_region2" {
  source = "./modules/aws_vpc"

  name = var.onprem_vpc_name_region2
  cidr = var.onprem_vpc_cidr_region2

  azs                                = slice(data.aws_availability_zones.available_region2.names, 0, 2)  # Select first two aws availability zones
  public_subnets                     = slice(cidrsubnets(var.onprem_vpc_cidr_region2, 2, 2, 2, 2), 0, 2) # Caculate consecuitive CIDR range for public subnets
  private_subnets                    = slice(cidrsubnets(var.onprem_vpc_cidr_region2, 2, 2, 2, 2), 2, 4) # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway                 = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw  = false
  providers = {
    aws = aws.secondary
  }
}

resource "aws_ec2_transit_gateway" "tgw_region2" {

  description = var.tgw_region2
  tags = {
    "Name" = var.tgw_region2
  }
  provider = aws.secondary
}


# Attach region2 VPCs to region2 tgw
resource "aws_ec2_transit_gateway_vpc_attachment" "region2" {
  for_each           = var.cloud_vpcs_region2
  subnet_ids         = module.cloud_vpc_region2[each.key].public_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw_region2.id
  vpc_id             = module.cloud_vpc_region2[each.key].vpc_id
  tags = {
    "Name" = each.key
  }
  provider = aws.secondary
}


# Create EIP for OnPrem VPN Gateway
resource "aws_eip" "onpregw_region2" {
  vpc = true
  tags = {
    Name = var.onprem_gw_name_region2
  }
  provider = aws.secondary
}


# Create customer gateway
resource "aws_customer_gateway" "cxgw_region2" {
  bgp_asn    = var.onpremgw_asn_region2
  ip_address = aws_eip.onpregw_region2.public_ip
  type       = "ipsec.1"

  tags = {
    Name = var.onprem_gw_name_region2
  }
  provider = aws.secondary
}


resource "aws_vpn_connection" "region2" {
  customer_gateway_id = aws_customer_gateway.cxgw_region2.id
  transit_gateway_id  = aws_ec2_transit_gateway.tgw_region2.id
  type                = aws_customer_gateway.cxgw_region2.type
  tags = {
    Name = var.onprem_gw_name_region2
  }
  provider = aws.secondary
}



# Store IPSec Key in Secret Manager

locals {
  region2_tunnel_1_psk_name = "${aws_vpn_connection.region2.id}-tunnel-1-psk"
  region2_tunnel_2_psk_name = "${aws_vpn_connection.region2.id}-tunnel-2-psk"
}
resource "aws_secretsmanager_secret" "region2_tunnel_1_psk" {
  name     = local.region2_tunnel_1_psk_name
  provider = aws.secondary
}

resource "aws_secretsmanager_secret_version" "region2_tunnel_1_psk" {
  secret_id     = aws_secretsmanager_secret.region2_tunnel_1_psk.id
  secret_string = jsonencode({ "psk" : "${aws_vpn_connection.region2.tunnel1_preshared_key}" })
  provider      = aws.secondary
}

resource "aws_secretsmanager_secret" "region2_tunnel_2_psk" {
  name     = local.region2_tunnel_2_psk_name
  provider = aws.secondary
}

resource "aws_secretsmanager_secret_version" "region2_tunnel_2_psk" {
  secret_id     = aws_secretsmanager_secret.region2_tunnel_2_psk.id
  secret_string = jsonencode({ "psk" : "${aws_vpn_connection.region2.tunnel2_preshared_key}" })
  provider      = aws.secondary
}


# Deploy CloudFormation Stack 
# Parameter reference: https://github.com/aws-samples/vpn-gateway-strongswan
# Or review local yaml file

resource "aws_cloudformation_stack" "region2_vpn_gateway" {
  name = "region2-vpn-gateway"

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    keyName = var.key_name
    myIP = data.http.ip.response_body
    pAuthType = "psk"
    # tunnel 1
    pTunnel1PskSecretName = local.region2_tunnel_1_psk_name
    pTunnel1VgwOutsideIpAddress = aws_vpn_connection.region2.tunnel1_address
    pTunnel1CgwInsideIpAddress = "${aws_vpn_connection.region2.tunnel1_cgw_inside_address}/${split("/",aws_vpn_connection.region2.tunnel1_inside_cidr)[1]}"
    pTunnel1VgwInsideIpAddress = "${aws_vpn_connection.region2.tunnel1_vgw_inside_address}/${split("/",aws_vpn_connection.region2.tunnel1_inside_cidr)[1]}"
    pTunnel1VgwBgpAsn = aws_vpn_connection.region2.tunnel1_bgp_asn
    pTunnel1BgpNeighborIpAddress = aws_vpn_connection.region2.tunnel1_vgw_inside_address
    # tunnel 2
    pTunnel2PskSecretName = local.region2_tunnel_2_psk_name
    pTunnel2VgwOutsideIpAddress = aws_vpn_connection.region2.tunnel2_address
    pTunnel2CgwInsideIpAddress = "${aws_vpn_connection.region2.tunnel2_cgw_inside_address}/${split("/",aws_vpn_connection.region2.tunnel2_inside_cidr)[1]}"
    pTunnel2VgwInsideIpAddress = "${aws_vpn_connection.region2.tunnel2_vgw_inside_address}/${split("/",aws_vpn_connection.region2.tunnel2_inside_cidr)[1]}"
    pTunnel2VgwBgpAsn = aws_vpn_connection.region2.tunnel2_bgp_asn
    pTunnel2BgpNeighborIpAddress = aws_vpn_connection.region2.tunnel2_vgw_inside_address

    pVpcId = module.onprem_vpc_region2.vpc_id
    pVpcCidr = module.onprem_vpc_region2.vpc_cidr_block
    pSubnetId = module.onprem_vpc_region2.public_subnets[0]
    pUseElasticIp = true
    pEipAllocationId = aws_eip.onpregw_region2.id
    pLocalBgpAsn = var.onpremgw_asn_region2
  }

  template_body = file("${path.module}/vpn-gateway-strongswan.yml")
  provider      = aws.secondary
}

# Add Test instances
module "region2_test_ec2" {
  for_each  = var.cloud_vpcs_region2
  source    = "jye-aviatrix/aws-linux-vm-public/aws"
  version   = "2.0.1"
  key_name  = var.key_name
  subnet_id = module.cloud_vpc_region2[each.key].public_subnets[0]
  vm_name   = each.key
  vpc_id    = module.cloud_vpc_region2[each.key].vpc_id
  providers = {
    aws = aws.secondary
  }
}

module "region2_onprem_test_ec2" {
  source    = "jye-aviatrix/aws-linux-vm-public/aws"
  version   = "2.0.1"
  key_name  = var.key_name
  subnet_id = module.onprem_vpc_region2.public_subnets[0]
  vm_name   = "region2-onprem-test-ec2"
  vpc_id    = module.onprem_vpc_region2.vpc_id
  providers = {
    aws = aws.secondary
  }
}
