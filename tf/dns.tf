resource "aws_route53_zone" "primary_dns_zone" {
  name = "mazgis47.com"
}

# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.primary_dns_zone.zone_id
#   name    = "www.mazgis47.com"
#   type    = "A"
#   ttl     = "300"
#   records = [aws_eip.lb.public_ip]
# }