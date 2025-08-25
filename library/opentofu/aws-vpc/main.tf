data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block

  tags = merge(var.tags, { Name = var.vpc_name })
}

resource "aws_subnet" "subnets" {

  for_each = {
    for idx, cidr in var.subnet_cidrs : cidr => idx
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.key
  availability_zone       = data.aws_availability_zones.available.names[each.value % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, { Name = "${var.vpc_name}-subnet-${format("%02d", each.value + 1)}" })

}