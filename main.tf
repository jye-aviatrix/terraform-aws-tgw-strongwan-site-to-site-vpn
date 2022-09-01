module "cloud_vpc_region1" {
  source = "./modules/aws_vpc"

  for_each = var.cloud_vpcs_region1
  name = each.key
  cidr = each.value

  azs                = slice(data.aws_availability_zones.available.names, 0, 2) # Select first two aws availability zones
  public_subnets     = slice(cidrsubnets(each.value, 2, 2, 2, 2), 0, 2) # Caculate consecuitive CIDR range for public subnets
  private_subnets    = slice(cidrsubnets(each.value, 2, 2, 2, 2), 2, 4) # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw = false
}

module "cloud_vpc_region2" {
  source = "./modules/aws_vpc"

  for_each = var.cloud_vpcs_region2
  name = each.key
  cidr = each.value

  azs                = slice(data.aws_availability_zones.available_region2.names, 0, 2) # Select first two aws availability zones
  public_subnets     = slice(cidrsubnets(each.value, 2, 2, 2, 2), 0, 2) # Caculate consecuitive CIDR range for public subnets
  private_subnets    = slice(cidrsubnets(each.value, 2, 2, 2, 2), 2, 4) # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw = false
  providers = {
    aws = aws.secondary
   }
}


module "onprem_vpc_region1" {
  source = "./modules/aws_vpc"

  name = var.onprem_vpc_name_region1
  cidr = var.onprem_vpc_cidr_region1

  azs                = slice(data.aws_availability_zones.available.names, 0, 2) # Select first two aws availability zones
  public_subnets     = slice(cidrsubnets(var.onprem_vpc_cidr_region1, 2, 2, 2, 2), 0, 2) # Caculate consecuitive CIDR range for public subnets
  private_subnets    = slice(cidrsubnets(var.onprem_vpc_cidr_region1, 2, 2, 2, 2), 2, 4) # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw = false
}

module "onprem_vpc_region2" {
  source = "./modules/aws_vpc"

  # for_each = var.onprem_vpcs_region2
  name = var.onprem_vpc_name_region2
  cidr = var.onprem_vpc_cidr_region2

  azs                = slice(data.aws_availability_zones.available_region2.names, 0, 2) # Select first two aws availability zones
  public_subnets     = slice(cidrsubnets(var.onprem_vpc_cidr_region2, 2, 2, 2, 2), 0, 2) # Caculate consecuitive CIDR range for public subnets
  private_subnets    = slice(cidrsubnets(var.onprem_vpc_cidr_region2, 2, 2, 2, 2), 2, 4) # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw = false
  providers = {
    aws = aws.secondary
   }
}



resource "aws_ec2_transit_gateway" "tgw_region1" {
  description = var.tgw_region1
  tags = {
    "Name" = var.tgw_region1
  }
}


resource "aws_ec2_transit_gateway" "tgw_region2" {

  description = var.tgw_region2
  tags = {
    "Name" = var.tgw_region2
  }
  provider = aws.secondary
}


# Create EIP for OnPrem VPN Gateway
resource "aws_eip" "onpregw_region1" {
  vpc = true
  tags = {
    Name = var.onprem_gw_name_region1
  }
}


# Create customer gateway
resource "aws_customer_gateway" "cxgw_region1" {
  bgp_asn    = var.onpremgw_asn_region1
  ip_address = aws_eip.onpregw_region1.public_ip
  type       = "ipsec.1"

  tags = {
    Name = var.onprem_gw_name_region1
  }
}


resource "aws_vpn_connection" "region1" {
  customer_gateway_id = aws_customer_gateway.cxgw_region1.id
  transit_gateway_id  = aws_ec2_transit_gateway.tgw_region1.id
  type                = aws_customer_gateway.cxgw_region1.type
  tags = {
    Name = var.onprem_gw_name_region1
  }
}



# Store IPSec Key in Secret Manager

locals {
  region1_tunnel_1_psk_name = "${aws_vpn_connection.region1.id}-tunnel-1-psk" 
  region1_tunnel_2_psk_name = "${aws_vpn_connection.region1.id}-tunnel-2-psk" 
}
resource "aws_secretsmanager_secret" "region1_tunnel_1_psk" {
  name =  local.region1_tunnel_1_psk_name
}

resource "aws_secretsmanager_secret_version" "region1_tunnel_1_psk" {
  secret_id = aws_secretsmanager_secret.region1_tunnel_1_psk.id
  secret_string = jsonencode({"psk":"${aws_vpn_connection.region1.tunnel1_preshared_key}"})
}

resource "aws_secretsmanager_secret" "region1_tunnel_2_psk" {
  name =  local.region1_tunnel_2_psk_name
}

resource "aws_secretsmanager_secret_version" "region1_tunnel_2_psk" {
  secret_id = aws_secretsmanager_secret.region1_tunnel_2_psk.id
  secret_string = jsonencode({"psk":"${aws_vpn_connection.region1.tunnel2_preshared_key}"})
}


# Deploy CloudFormation Stack 
# Parameter reference: https://github.com/aws-samples/vpn-gateway-strongswan
# Or review local yaml file

resource "aws_cloudformation_stack" "region_1vpn_gateway" {
  name = "region1-vpn-gateway"

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    keyName = var.key_name
    myIP = data.http.ip.body
    pAuthType = "psk"
    # tunnel 1
    pTunnel1PskSecretName = local.region1_tunnel_1_psk_name
    pTunnel1VgwOutsideIpAddress = aws_vpn_connection.region1.tunnel1_address
    pTunnel1CgwInsideIpAddress = "${aws_vpn_connection.region1.tunnel1_cgw_inside_address}/${split("/",aws_vpn_connection.region1.tunnel1_inside_cidr)[1]}"
    pTunnel1VgwInsideIpAddress = "${aws_vpn_connection.region1.tunnel1_vgw_inside_address}/${split("/",aws_vpn_connection.region1.tunnel1_inside_cidr)[1]}"
    pTunnel1VgwBgpAsn = aws_vpn_connection.region1.tunnel1_bgp_asn
    pTunnel1BgpNeighborIpAddress = aws_vpn_connection.region1.tunnel1_vgw_inside_address
    # tunnel 2
    pTunnel2PskSecretName = local.region1_tunnel_2_psk_name
    pTunnel2VgwOutsideIpAddress = aws_vpn_connection.region1.tunnel2_address
    pTunnel2CgwInsideIpAddress = "${aws_vpn_connection.region1.tunnel2_cgw_inside_address}/${split("/",aws_vpn_connection.region1.tunnel2_inside_cidr)[1]}"
    pTunnel2VgwInsideIpAddress = "${aws_vpn_connection.region1.tunnel2_vgw_inside_address}/${split("/",aws_vpn_connection.region1.tunnel2_inside_cidr)[1]}"
    pTunnel2VgwBgpAsn = aws_vpn_connection.region1.tunnel2_bgp_asn
    pTunnel2BgpNeighborIpAddress = aws_vpn_connection.region1.tunnel2_vgw_inside_address

    pVpcId = module.onprem_vpc_region1.vpc_id
    pVpcCidr = module.onprem_vpc_region1.vpc_cidr_block
    pSubnetId = module.onprem_vpc_region1.public_subnets[0]
    pUseElasticIp = true
    pEipAllocationId = aws_eip.onpregw_region1.id
    pLocalBgpAsn = var.onpremgw_asn_region1
  }

  template_body = file("${path.module}/vpn-gateway-strongswan.yml")
}

# # Add Test instances
# module "cloud_test_ec2" {
#   source  = "jye-aviatrix/aws-linux-vm-public/aws"
#   version = "1.0.3"
#   key_name = var.key_name
#   region = var.region
#   subnet_id = module.cloudvpc.public_subnets[0]
#   vm_name = "cloud-test-ec2"
#   vpc_id = module.cloudvpc.vpc_id
# }
# module "onprem_test_ec2" {
#   source  = "jye-aviatrix/aws-linux-vm-public/aws"
#   version = "1.0.3"
#   key_name = var.key_name
#   region = var.region
#   subnet_id = module.onpremvpc.public_subnets[0]
#   vm_name = "onprem-test-ec2"
#   vpc_id = module.onpremvpc.vpc_id
# }

# # Add Cloud Routes to OnPrem route tables, point to the StrongWAN gateway

# resource "aws_route" "public_vpn_gw" {
#   count                  = length(module.onpremvpc.public_route_table_ids)
#   route_table_id         = module.onpremvpc.public_route_table_ids[count.index]
#   destination_cidr_block = var.cloud_vpc_cidr
#   network_interface_id = aws_cloudformation_stack.vpn_gateway.outputs.NicID
# }
# resource "aws_route" "private_vpn_gw" {
#   count                  = length(module.onpremvpc.private_route_table_ids)
#   route_table_id         = module.onpremvpc.private_route_table_ids[count.index]
#   destination_cidr_block = var.cloud_vpc_cidr
#   network_interface_id = aws_cloudformation_stack.vpn_gateway.outputs.NicID
# }