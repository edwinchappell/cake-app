output "alb_dns_name" {
  description = "Cake API spec URI"
  value       = "${aws_lb.main.*.dns_name[0]}/docs"
}

