variable "local_path" {
  type = "string"
  description = "The local path where key and certificate will be saved"
}

variable "filename" {
  type = "string"
  description = "The filename of key and certificate"
}

variable "ca_key_algorithm" {
  type = "string"
  description = "The name of the algorithm to use for the CA key"
}

variable "ca_private_key_pem" {
  type = "string"
  description = "PEM-encoded private key for the CA"
}

variable "ca_cert_pem" {
  type = "string"
  description = "PEM-encoded certificate data for the CA"
}

variable "algorithm" {
  default = "RSA"
  description = "The name of the algorithm to use for the key"
}

variable "rsa_bits" {
  default = 2048
  description = "The size of the generated RSA key in bits. Defaults to 2048"
}

variable "common_name" {
  type = "string"
  description = "The common name for which a certificate is being requested"
}

variable "organization" {
  type = "string"
  description = "The organization name for which a certificate is being requested"
}

variable "dns_names" {
  type = "list"
  default = []
  description = "List of DNS names for which a certificate is being requested"
}

variable "ip_addresses" {
  type = "list"
  default = []
  description = "List of IP addresses for which a certificate is being requested"
}

variable "allowed_uses" {
  type = "list"
  default = [
    "client_auth",
    "server_auth",
    "digital_signature",
    "key_encipherment"]
  description = "List of keywords each describing a use that is permitted for the issued certificate"
}

variable "chmod_command" {
  type = "string"
  default = "chmod 600 %v"
  description = "Template of the command executed on the private key file"
}

variable "server_ip_address" {
  default = "127.0.0.1"
}

variable "cluster_name" {
  default = "kubernetes-the-hard-way"
  description = "The name of kubernetes cluster name to use for kubeconfig"
}

variable "generate_kubeconfig" {
  type = "string"
  default = "true"
}
