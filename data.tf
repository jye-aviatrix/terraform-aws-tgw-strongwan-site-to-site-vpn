data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_availability_zones" "available_region2" {
  state = "available"
  provider = aws.secondary
}

data "http" "ip" {
  url = "https://ifconfig.me"
}