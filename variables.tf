variable "region1" {
  default = "us-east-1"
  description = "Specify the region of the deployment"
}

variable "region2" {
  default = "us-east-2"
  description = "Specify the region of the deployment"
}

variable "cloud_vpcs_region1" {
  default = {
    ue1shared = "10.100.1.0/24"
    ue1prod = "10.100.2.0/24"
    ue1dev = "10.100.3.0/24"
  }
}

variable "cloud_vpcs_region2" {
  default = {
    ue2shared = "10.200.1.0/24"
    ue2prod = "10.200.2.0/24"
    ue2dev = "10.200.3.0/24"
  }
}

variable "onprem_vpcs_region1" {
  default = {
    ue1onprem = "10.10.1.0/24"
  }
}

variable "onprem_vpcs_region2" {
  default = {
    ue2onprem = "10.20.1.0/24"
  }
}

variable "tgw_region1" {
  default = {
    ue1tgw = "ue1tgw"
  }
}

variable "tgw_region2" {
  default = {
    ue2tgw = "ue2tgw"
  }
}

# variable "cloud_vpc_name" {
#   default = "cloud_vpc"
#   description = "Specify cloud side VPC name"
# }

# variable "cloud_vpc_cidr" {
#   default = "10.0.100.0/24"
#   description = "Specify cloud side VPC CIDR"
# }

# variable "onprem_vpc_name" {
#     default = "onprem_vpc"
#     description = "Specify on-prem VPC name"  
# }

# variable "onprem_vpc_cidr" {
#     default = "10.0.200.0/24"
#     description = "Specify on-prem VPC CIDR"  
# }

# variable "onprem_asn" {
#   default = 65000
#   description = "ASN of onprem VPN gateway"
# }

# variable "onprem_vpn_gw_name" {
#   default = "onprem_vpn_gw"
#   description = "OnPrem VPN gateway name"
# }

# variable "key_name" {
#   description = "Provide EC2 Key Pair name for test machines launched in Public subnets"
# }