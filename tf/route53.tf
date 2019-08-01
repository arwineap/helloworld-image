resource "aws_route53_zone" "foobar_internal" {
  name   = "foobar.internal"
  vpc {
    vpc_id = "${aws_vpc.vpc.id}"
  }
}
