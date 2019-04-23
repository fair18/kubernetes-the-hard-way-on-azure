apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${ca_data}
    server: ${server_ip_address}
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: ${username}
  name: ${context_name}
current-context: ${context_name}
kind: Config
preferences: {}
users:
- name: ${username}
  user:
    client-certificate-data: ${client_crt_data}
    client-key-data: ${client_key_data}
