data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "ip" {
  url = "https://ifconfig.me"
}