output "private_key_pem" {
  value = tls_private_key.default.private_key_pem
}

output "cert_pem" {
  value = tls_locally_signed_cert.default.cert_pem
}

output "private_key_filename" {
  value = local_file.tls_key.filename
}

output "cert_filename" {
  value = local_file.tls_crt.filename
}
