locals {
  file_path = format("%v/certs", path.cwd)
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning a CA and generating TLS certificates
# ---------------------------------------------------------------------------------------------------------------------
resource "tls_private_key" "ca" {
  algorithm = var.algorithm
  rsa_bits = var.rsa_bits
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm = tls_private_key.ca.algorithm
  private_key_pem = tls_private_key.ca.private_key_pem

  validity_period_hours = 8760
  is_ca_certificate = true

  subject {
    common_name = "Kubernetes"
    country = "CA"
    locality = "Toronto"
    organization = "Kubernetes"
    organizational_unit = "CA"
    province = "Ontario"
  }

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}

resource "local_file" "ca" {
  filename = format("%v/certs/ca.pem", path.cwd)
  content = tls_self_signed_cert.ca.cert_pem
  provisioner "local-exec" {
    command = format("chmod 0600 %v", self.filename)
  }
}

resource "local_file" "ca-key" {
  filename = format("%v/certs/ca-key.pem", path.cwd)
  content = tls_private_key.ca.private_key_pem
  provisioner "local-exec" {
    command = format("chmod 0600 %v", self.filename)
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Admin Client Certificate
# ---------------------------------------------------------------------------------------------------------------------
module "admin" {
  source = "./tls"

  common_name = "admin"
  organization = "system:masters"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  filename = "admin"
  local_path = local.file_path

  server_ip_address = azurerm_public_ip.default.ip_address
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Controller Manager Client Certificate
# ---------------------------------------------------------------------------------------------------------------------
module "kube-controller-manager" {
  source = "./tls"

  common_name = "system:kube-controller-manager"
  organization = "system:kube-controller-manager"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  filename = "kube-controller-manager"
  local_path = local.file_path
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Kube Proxy Client Certificate
# ---------------------------------------------------------------------------------------------------------------------
module "kube-proxy" {
  source = "./tls"

  common_name = "system:kube-proxy"
  organization = "system:node-proxier"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  filename = "kube-proxy"
  local_path = local.file_path

  server_ip_address = azurerm_public_ip.default.ip_address
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Scheduler Client Certificate
# ---------------------------------------------------------------------------------------------------------------------
module "kube-scheduler" {
  source = "./tls"

  common_name = "system:kube-scheduler"
  organization = "system:kube-scheduler"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  filename = "kube-scheduler"
  local_path = local.file_path
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Service Account Key Pair
# ---------------------------------------------------------------------------------------------------------------------
module "service-account" {
  source = "./tls"

  common_name = "service-accounts"
  organization = "Kubernetes"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  filename = "service-account"
  local_path = local.file_path

  generate_kubeconfig = "false"
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Kubernetes API Server Certificate
# ---------------------------------------------------------------------------------------------------------------------
module "kubernetes-api-server" {
  source = "./tls"

  common_name = "kubernetes"
  organization = "Kubernetes"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  ip_addresses = [
    "127.0.0.1",
    "10.32.0.1",
    azurerm_public_ip.default.ip_address,
    module.controllers.private_ips[0],
    module.controllers.private_ips[1],
    module.controllers.private_ips[2],
  ]

  dns_names = [
    "kubernetes.default"]

  filename = "kubernetes"
  local_path = local.file_path

  generate_kubeconfig = "false"
}
# ---------------------------------------------------------------------------------------------------------------------
# Provisioning the Kubelet Client Certificates
# ---------------------------------------------------------------------------------------------------------------------
module "worker-0" {
  source = "./tls"

  common_name = "system:node:${module.workers.vm_hostname[0]}"
  organization = "system:nodes"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  ip_addresses = [
    module.workers.public_ips[0],
    module.workers.private_ips[0],
  ]

  dns_names = [
    module.workers.vm_hostname[0]]

  filename = module.workers.vm_hostname[0]
  local_path = local.file_path

  server_ip_address = azurerm_public_ip.default.ip_address
}

module "worker-1" {
  source = "./tls"

  common_name = "system:node:${module.workers.vm_hostname[1]}"
  organization = "system:nodes"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  ip_addresses = [
    module.workers.public_ips[1],
    module.workers.private_ips[1],
  ]

  dns_names = [
    module.workers.vm_hostname[1]]

  filename = module.workers.vm_hostname[1]
  local_path = local.file_path

  server_ip_address = azurerm_public_ip.default.ip_address
}

module "worker-2" {
  source = "./tls"

  common_name = "system:node:${module.workers.vm_hostname[2]}"
  organization = "system:nodes"

  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  ip_addresses = [
    module.workers.public_ips[2],
    module.workers.private_ips[2],
  ]

  dns_names = [
    module.workers.vm_hostname[2]]

  filename = module.workers.vm_hostname[2]
  local_path = local.file_path

  server_ip_address = azurerm_public_ip.default.ip_address
}
