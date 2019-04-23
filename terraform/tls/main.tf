resource "tls_private_key" "default" {
  algorithm = "${var.algorithm}"
  rsa_bits = "${var.rsa_bits}"
}

resource "tls_cert_request" "default" {
  key_algorithm = "${tls_private_key.default.algorithm}"
  private_key_pem = "${tls_private_key.default.private_key_pem}"
  dns_names = [
    "${var.dns_names}"]
  ip_addresses = [
    "${var.ip_addresses}"]

  "subject" {
    common_name = "${var.common_name}"
    country = "CA"
    locality = "Toronto"
    organization = "${var.organization}"
    organizational_unit = "Kubernetes The Hard Way"
    province = "Ontario"
  }
}

resource "tls_locally_signed_cert" "default" {
  cert_request_pem = "${tls_cert_request.default.cert_request_pem}"
  ca_key_algorithm = "${var.ca_key_algorithm}"
  ca_private_key_pem = "${var.ca_private_key_pem}"
  ca_cert_pem = "${var.ca_cert_pem}"
  validity_period_hours = 8760
  allowed_uses = "${var.allowed_uses}"
}

resource "local_file" "tls_key" {
  filename = "${format("%v/%v-key.pem", var.local_path, var.filename)}"
  content = "${tls_private_key.default.private_key_pem}"

  provisioner "local-exec" {
    command = "${format(var.chmod_command, self.filename)}"
  }
}

resource "local_file" "tls_crt" {
  filename = "${format("%v/%v.pem", var.local_path, var.filename)}"
  content = "${tls_locally_signed_cert.default.cert_pem}"

  provisioner "local-exec" {
    command = "${format(var.chmod_command, self.filename)}"
  }
}

data "template_file" "kubeconfig" {
  count = "${var.generate_kubeconfig == "true" ? 1 : 0}"
  template = "${file(format("%v/%s", path.module, "kubeconfig.tpl"))}"

  vars {
    ca_data = "${base64encode(var.ca_cert_pem)}"
    server_ip_address = "${format("https://%v:6443", var.server_ip_address)}"
    cluster_name = "${var.cluster_name}"
    username = "${var.common_name}"
    context_name = "default"
    client_crt_data = "${base64encode(tls_locally_signed_cert.default.cert_pem)}"
    client_key_data = "${base64encode(tls_private_key.default.private_key_pem)}"
  }
}

resource "local_file" "kubeconfig" {
  count = "${var.generate_kubeconfig == "true" ? 1 : 0}"
  filename = "${format("%v/config/%v.kubeconfig", path.cwd, var.filename)}"
  content = "${data.template_file.kubeconfig.rendered}"
}
