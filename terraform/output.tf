output "kubernetes_pip" {
  value = "${azurerm_public_ip.default.ip_address}"
}

output "controller_pips" {
  value = "${module.controllers.public_ips}"
}

output "worker_pips" {
  value = "${module.workers.public_ips}"
}
