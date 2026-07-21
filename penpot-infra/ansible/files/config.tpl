Host bastion
  HostName ${BASTION_PUBLIC_IP}
  User admin
  Port 20100
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes

Host prometheus
  HostName ${PROMETHEUS_PRIVATE_IP}
  User admin
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
  ProxyJump bastion

Host grafana
  HostName ${GRAFANA_PRIVATE_IP}
  User admin
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
  ProxyJump bastion