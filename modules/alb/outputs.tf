output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arns" {
  description = "ARNs de los target groups por servicio"
  value       = { for k, v in aws_lb_target_group.services : k => v.arn }
}

output "listener_arn" {
  description = "ARN del listener HTTP"
  value       = aws_lb_listener.http.arn
}
