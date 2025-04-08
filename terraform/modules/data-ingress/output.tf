output "load_balancer_ip" {
  value = local.load_balancer_ip
}

output "domain_name" {
  value = "${local.load_balancer_ip}.nip.io"
}

output "domain_name_http" {
  value = "http://${local.load_balancer_ip}.nip.io"
}

output "domain_name_https" {
  value = "https://${local.load_balancer_ip}.nip.io"
}
