# terraform-aws-vgw-strongwan-site-to-site-vpn
Create AWS VGW on one VPC, and EC2 instance with StrongWAN on another VPC, create Site to Site VPN between them

* This module creates two VPCs in AWS, default us-east-1 region
* One VPC simulate on-premise data center, with an instance with Quuaga StrongWan deployed in public subnet, acting as IPSec BGP router connect from on-premise to cloud
* One VPC have VGW attached and will connect to Quuaga via IPSec/BGP.
* Test instance deployed in both sides public subnets.
* VGW receives BGP route from Quuaga StrongWan, then the route tables propagate the route received from VGW.

![](20220831181831.png)  

This module is inspired by: https://github.com/aws-samples/vpn-gateway-strongswan
Original test will require you create VPC, test instance, change route tables, create customer gateway, VGW, and VPN connection and download configuration, all manually.

This module automats everything. You need to specify EC2 key pair to be used for the test instances.

Note, IKEv1 is been used here.

## Example
```terraform
module "vgw-strongwan-site-to-site-vpn" {
  source  = "jye-aviatrix/vgw-strongwan-site-to-site-vpn/aws"
  version = "1.0.1"
  key_name  = "ec2-key-pair"
}

output "strongwan" {
  value = module.vgw-strongwan-site-to-site-vpn
}
```

## Output
```
strongwan = {
  "cloud_test_ec2" = {
    "instance_id" = "i-00baaff84299eab88"
    "private_ip" = "10.0.100.15"
    "public_ip" = "54.237.144.216"
    "ssh" = "ssh -i ec2-key-pair.pem ubuntu@54.237.144.216"
  }
  "onprem_test_ec2" = {
    "instance_id" = "i-0b22471d51b79dfb3"
    "private_ip" = "10.0.200.13"
    "public_ip" = "3.220.231.142"
    "ssh" = "ssh -i ec2-key-pair.pem ubuntu@3.220.231.142"
  }
  "strongWanGW" = {
    "instance_id" = "i-0cec0ea06cbb18f37"
    "private_ip" = "10.0.200.9"
    "public_ip" = "34.230.195.219"
    "ssh" = "ssh -i ec2-key-pair.pem ec2-user@34.230.195.219"
  }
}
```

Estimated cost
```
 Name                                                       Monthly Qty  Unit                    Monthly Cost

 aws_eip.onpremvpngw
 └─ IP address (if unused)                                          730  hours                          $3.65

 aws_secretsmanager_secret.tunnel_1_psk
 ├─ Secret                                                            1  months                         $0.40
 └─ API requests                                      Monthly cost depends on usage: $0.05 per 10k requests

 aws_secretsmanager_secret.tunnel_2_psk
 ├─ Secret                                                            1  months                         $0.40
 └─ API requests                                      Monthly cost depends on usage: $0.05 per 10k requests

 aws_vpn_connection.main
 └─ VPN connection                                                  730  hours                         $36.50

 module.cloud_test_ec2.aws_instance.this
 ├─ Instance usage (Linux/UNIX, on-demand, t2.micro)                730  hours                          $8.47
 └─ root_block_device
    └─ Storage (general purpose SSD, gp2)                             8  GB                             $0.80

 module.onprem_test_ec2.aws_instance.this
 ├─ Instance usage (Linux/UNIX, on-demand, t2.micro)                730  hours                          $8.47
 └─ root_block_device
    └─ Storage (general purpose SSD, gp2)                             8  GB                             $0.80

 OVERALL TOTAL                                                                                         $59.49
```