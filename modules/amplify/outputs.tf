output "app_id" {
  description = "ID de la app Amplify"
  value       = aws_amplify_app.main.id
}

output "app_url" {
  description = "URL por defecto de la app Amplify"
  value       = "https://${var.branch_name}.${aws_amplify_app.main.default_domain}"
}

output "default_domain" {
  description = "Dominio por defecto de Amplify"
  value       = aws_amplify_app.main.default_domain
}

output "branch_name" {
  description = "Nombre de la rama desplegada"
  value       = aws_amplify_branch.main.branch_name
}
