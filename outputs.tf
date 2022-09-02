output "region1_test_ec2" {
  value = module.region1_test_ec2
}

output "region1_onprem_test_ec2" {
  value = module.region1_onprem_test_ec2
}

output "region1_onprem_gw" {
  value = {
    "instance_id" = aws_cloudformation_stack.region1_vpn_gateway.outputs.InstanceID
    "private_ip" = aws_cloudformation_stack.region1_vpn_gateway.outputs.PrivateIp
    "public_ip" = aws_eip.onpregw_region1.public_ip
    "ssh" = "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.onpregw_region1.public_ip}"
  }
}


output "region2_test_ec2" {
  value = module.region2_test_ec2
}

output "region2_onprem_test_ec2" {
  value = module.region2_onprem_test_ec2
}

output "region2_onprem_gw" {
  value = {
    "instance_id" = aws_cloudformation_stack.region2_vpn_gateway.outputs.InstanceID
    "private_ip" = aws_cloudformation_stack.region2_vpn_gateway.outputs.PrivateIp
    "public_ip" = aws_eip.onpregw_region2.public_ip
    "ssh" = "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.onpregw_region2.public_ip}"
  }
}