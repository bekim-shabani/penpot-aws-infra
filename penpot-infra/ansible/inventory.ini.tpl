[public]
bastion ansible_host=${BASTION_PUBLIC_IP} ansible_user=admin ansible_port=20100

[private]
prometheus ansible_host=${PROMETHEUS_PRIVATE_IP} ansible_user=admin ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -p 20100 -q admin@${BASTION_PUBLIC_IP}"'
grafana ansible_host=${GRAFANA_PRIVATE_IP} ansible_user=admin ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -p 20100 -q admin@${BASTION_PUBLIC_IP}"'

[private:vars]
BASTION_PRIVATE_IP=${BASTION_PRIVATE_IP}

[public:vars]
RDS_PREPROD_ENDPOINT=${RDS_PREPROD_ENDPOINT}
RDS_PROD_ENDPOINT=${RDS_PROD_ENDPOINT}
RDS_PASSWORD=${RDS_PASSWORD}