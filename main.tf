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

  for_each = var.onprem_vpcs_region1
  name = each.key
  cidr = each.value

  azs                = slice(data.aws_availability_zones.available.names, 0, 2) # Select first two aws availability zones
  public_subnets     = slice(cidrsubnets(each.value, 2, 2, 2, 2), 0, 2) # Caculate consecuitive CIDR range for public subnets
  private_subnets    = slice(cidrsubnets(each.value, 2, 2, 2, 2), 2, 4) # Caculate consecuitive CIDR range for private subnets
  enable_vpn_gateway = false
  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw = false
}

module "onprem_vpc_region2" {
  source = "./modules/aws_vpc"

  for_each = var.onprem_vpcs_region2
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



resource "aws_ec2_transit_gateway" "tgw_region1" {
  for_each = var.tgw_region1
  description = each.value
  tags = {
    "Name" = each.key
  }
}


resource "aws_ec2_transit_gateway" "tgw_region2" {
  for_each = var.tgw_region2
  description = each.value
  tags = {
    "Name" = each.key
  }
  provider = aws.secondary
}


# # Create EIP for OnPrem VPN Gateway
# resource "aws_eip" "onpremvpngw" {
#   vpc = true
#   tags = {
#     Name = var.onprem_vpn_gw_name
#   }
# }


# # Create customer gateway
# resource "aws_customer_gateway" "main" {
#   bgp_asn    = var.onprem_asn
#   ip_address = aws_eip.onpremvpngw.public_ip
#   type       = "ipsec.1"

#   tags = {
#     Name = var.onprem_vpn_gw_name
#   }
# }


# # Create VPN connection
# resource "aws_vpn_connection" "main" {
#   vpn_gateway_id      = module.cloudvpc.vgw_id
#   customer_gateway_id = aws_customer_gateway.main.id
#   type                = "ipsec.1"
#   static_routes_only  = false
#   tags = {
#     Name = var.onprem_vpn_gw_name
#   }
# }


# # Store IPSec Key in Secret Manager

# locals {
#   tunnel_1_psk_name = "${aws_vpn_connection.main.id}-tunnel-1-psk" 
#   tunnel_2_psk_name = "${aws_vpn_connection.main.id}-tunnel-2-psk" 
# }
# resource "aws_secretsmanager_secret" "tunnel_1_psk" {
#   name =  local.tunnel_1_psk_name
# }



# resource "aws_secretsmanager_secret_version" "tunnel_1_psk" {
#   secret_id = aws_secretsmanager_secret.tunnel_1_psk.id
#   secret_string = jsonencode({"psk":"${aws_vpn_connection.main.tunnel1_preshared_key}"})
# }

# resource "aws_secretsmanager_secret" "tunnel_2_psk" {
#   name = local.tunnel_2_psk_name  
# }

# resource "aws_secretsmanager_secret_version" "tunnel_2_psk" {
#   secret_id = aws_secretsmanager_secret.tunnel_2_psk.id
#   secret_string = jsonencode({"psk":"${aws_vpn_connection.main.tunnel2_preshared_key}"})
# }

# # Deploy CloudFormation Stack 
# # Parameter reference: https://github.com/aws-samples/vpn-gateway-strongswan
# # Or review local yaml file

# resource "aws_cloudformation_stack" "vpn_gateway" {
#   name = "vpn-gateway"

#   capabilities = ["CAPABILITY_NAMED_IAM"]

#   parameters = {
#     keyName = var.key_name
#     myIP = data.http.ip.body
#     pAuthType = "psk"
#     # tunnel 1
#     pTunnel1PskSecretName = local.tunnel_1_psk_name
#     pTunnel1VgwOutsideIpAddress = aws_vpn_connection.main.tunnel1_address
#     pTunnel1CgwInsideIpAddress = "${aws_vpn_connection.main.tunnel1_cgw_inside_address}/${split("/",aws_vpn_connection.main.tunnel1_inside_cidr)[1]}"
#     pTunnel1VgwInsideIpAddress = "${aws_vpn_connection.main.tunnel1_vgw_inside_address}/${split("/",aws_vpn_connection.main.tunnel1_inside_cidr)[1]}"
#     pTunnel1VgwBgpAsn = aws_vpn_connection.main.tunnel1_bgp_asn
#     pTunnel1BgpNeighborIpAddress = aws_vpn_connection.main.tunnel1_vgw_inside_address
#     # tunnel 2
#     pTunnel2PskSecretName = local.tunnel_2_psk_name
#     pTunnel2VgwOutsideIpAddress = aws_vpn_connection.main.tunnel2_address
#     pTunnel2CgwInsideIpAddress = "${aws_vpn_connection.main.tunnel2_cgw_inside_address}/${split("/",aws_vpn_connection.main.tunnel2_inside_cidr)[1]}"
#     pTunnel2VgwInsideIpAddress = "${aws_vpn_connection.main.tunnel2_vgw_inside_address}/${split("/",aws_vpn_connection.main.tunnel2_inside_cidr)[1]}"
#     pTunnel2VgwBgpAsn = aws_vpn_connection.main.tunnel2_bgp_asn
#     pTunnel2BgpNeighborIpAddress = aws_vpn_connection.main.tunnel2_vgw_inside_address

#     pVpcId = module.onpremvpc.vpc_id
#     pVpcCidr = module.onpremvpc.vpc_cidr_block
#     pSubnetId = module.onpremvpc.public_subnets[0]
#     pUseElasticIp = true
#     pEipAllocationId = aws_eip.onpremvpngw.id
#     pLocalBgpAsn = var.onprem_asn
#   }

#   template_body = file("${path.module}/vpn-gateway-strongswan.yml")
# }

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