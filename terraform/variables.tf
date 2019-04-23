variable "resource_group" {
  default = "kubernetes-1"
}

variable "location" {
  default = "eastus 2"
}

variable "vnet_name" {
  default = "kubernetes-vnet"
}

variable "vnet_addr_space" {
  default = "10.0.0.0/8"
}

variable "subnet_name" {
  default = "kubernetes-subnet"
}

variable "nsg_name" {
  default = "kubernetes-nsg"
}

variable "nsg_api_server_port_range" {
  default = 6443
}

variable "nsg_protocol" {
  default = "tcp"
}

variable "pip_name" {
  default = "kubernetes-pip"
}

variable "routes_table_name" {
  default = "kubernetes-routes"
}

variable "route_name" {
  default = "kubernetes-route-10-200-index-0-24"
}

variable "route_address_prefix" {
  default = "10.200.0.0/16"
}

variable "lb_name" {
  default = "kubernetes-lb"
}

variable "lb_frontend_ip_cfg_name" {
  default = "kubernetes-pip-address"
}

variable "lb_probe_name" {
  default = "kubernetes-apiserver-probe"
}

variable "lb_rule_name" {
  default = "kubernetes-apiserver-rule"
}

variable "lb_backend_address_pool_name" {
  default = "kubernetes-lb-pool"
}

variable "node_instances" {
  default = "3"
}

variable "vm_os_publisher" {
  default = "Canonical"
}

variable "vm_os_simple" {
  default = "UbuntuServer"
}

variable "vm_os_sku" {
  default = "18.04-LTS"
}

variable "vm_size" {
  default = "Standard_D4_v3"
}

variable "vm_enable_accelerated_networking" {
  default = "false"
}

variable "vm_boot_diagnostics" {
  default = "false"
}

variable "admin_username" {
  default = "azureuser"
}

variable "algorithm" {
  default = "RSA"
}

variable "rsa_bits" {
  default = 2048
}

variable "ssh_key_path" {
  default = "~/.ssh/id_azure.pub"
}

variable "ssh_file_name" {
  type        = "string"
  description = "Application or solution name (e.g. `app`)"
  default = "id_rsa"
}

variable "private_key_extension" {
  type        = "string"
  default     = ".pem"
  description = "Private key extension"
}

variable "public_key_extension" {
  type        = "string"
  default     = ".pub"
  description = "Public key extension"
}

variable "chmod_command" {
  type        = "string"
  default     = "chmod 600 %v"
  description = "Template of the command executed on the private key file"
}
