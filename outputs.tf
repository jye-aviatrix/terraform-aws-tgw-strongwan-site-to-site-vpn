output "region1_test_ec2" {
  value = module.region1_test_ec2
}

output "region1_onprem_test_ec2" {
  value = module.region1_onprem_test_ec2
}

# output "strongWanGW" {
#   value = {
#     "instance_id" = aws_cloudformation_stack.vpn_gateway.outputs.InstanceID
#     "private_ip" = aws_cloudformation_stack.vpn_gateway.outputs.PrivateIp
#     "public_ip" = aws_eip.onpremvpngw.public_ip
#     "ssh" = "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.onpremvpngw.public_ip}"
#   }
# }