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

variable "onprem_vpc_name_region1" {
  default = "ue1onprem"
}

variable "onprem_vpc_name_region2" {
  default = "ue2onprem"
}
variable "onprem_vpc_cidr_region1" {
  default = "10.10.1.0/24"
}
variable "onprem_vpc_cidr_region2" {
  default = "10.20.1.0/24"
}
variable "tgw_region1" {
  default = "ue1tgw"
}

variable "tgw_region2" {
  default = "ue2tgw"  
}



variable "onprem_gw_name_region1" {
  default = "ue1onpremgw"
  description = "OnPrem VPN gateway name"
}

variable "onpremgw_asn_region1" {
  default = 65001
  description = "ASN of onprem VPN gateway"
}

variable "onprem_gw_name_region2" {
  default = "ue2onpremgw"
  description = "OnPrem VPN gateway name"
}

variable "onpremgw_asn_region2" {
  default = 65002
  description = "ASN of onprem VPN gateway"
}

variable "key_name" {
  description = "Provide EC2 Key Pair name for test machines launched in Public subnets"
}