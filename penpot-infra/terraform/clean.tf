# ============================================================
# cleanup.tf — Nettoyage automatique avant terraform destroy
# 1. Webhook ALB supprimé
# 2. Finalizers ingress retirés
# 3. Finalizers namespaces retirés (patch + API)
# 4. ALB supprimé + sleep 30s
# 5. Target Groups orphelins supprimés
# 6. Instances EKS terminées + sleep 60s
# 7. ENIs disponibles supprimées
# 8. Security Groups supprimés
# ============================================================

resource "null_resource" "cleanup_before_destroy" {
  triggers = {
    cluster_name = var.cluster_name
    aws_region   = var.aws_region
    vpc_id       = aws_vpc.main.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      echo "=== Cleanup avant destroy ==="

      # 1. Supprime le webhook ALB controller
      kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook         --ignore-not-found 2>/dev/null || true

      # 2. Retire les finalizers des ingress
      kubectl patch ingress app-ingress -n preprod         -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
      kubectl patch ingress app-ingress -n prod         -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true

      # 3. Retire les finalizers des namespaces via patch et API
      kubectl patch namespace preprod         -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
      kubectl patch namespace prod         -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true

      kubectl get namespace preprod -o json 2>/dev/null |         python3 -c "import sys,json; d=json.load(sys.stdin); d['spec']['finalizers']=[]; print(json.dumps(d))" |         kubectl replace --raw /api/v1/namespaces/preprod/finalize -f - 2>/dev/null || true
      kubectl get namespace prod -o json 2>/dev/null |         python3 -c "import sys,json; d=json.load(sys.stdin); d['spec']['finalizers']=[]; print(json.dumps(d))" |         kubectl replace --raw /api/v1/namespaces/prod/finalize -f - 2>/dev/null || true

      # 4. Supprime l'ALB créé par le controller
      ALB_ARN=$(aws elbv2 describe-load-balancers         --names ${self.triggers.cluster_name}-alb         --region ${self.triggers.aws_region}         --query "LoadBalancers[0].LoadBalancerArn"         --output text 2>/dev/null || echo "")

      if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
        echo "Suppression ALB: $ALB_ARN"
        aws elbv2 delete-load-balancer           --load-balancer-arn $ALB_ARN           --region ${self.triggers.aws_region}
        sleep 30
      fi

      # 5. Supprime les target groups orphelins
      for TG_ARN in $(aws elbv2 describe-target-groups         --region ${self.triggers.aws_region}         --query "TargetGroups[?contains(TargetGroupName,'k8s-preprod') || contains(TargetGroupName,'k8s-prod')].TargetGroupArn"         --output text 2>/dev/null); do
        echo "Suppression TG: $TG_ARN"
        aws elbv2 delete-target-group           --target-group-arn $TG_ARN           --region ${self.triggers.aws_region} 2>/dev/null || true
      done

      # 6. Termine les instances EKS nodes
      for INSTANCE_ID in $(aws ec2 describe-instances         --filters           "Name=vpc-id,Values=${self.triggers.vpc_id}"           "Name=instance-state-name,Values=running,stopped"           "Name=tag:eks:cluster-name,Values=${self.triggers.cluster_name}"         --query "Reservations[].Instances[].InstanceId"         --region ${self.triggers.aws_region}         --output text 2>/dev/null); do
        echo "Terminaison instance: $INSTANCE_ID"
        aws ec2 terminate-instances           --instance-ids $INSTANCE_ID           --region ${self.triggers.aws_region} 2>/dev/null || true
      done
      sleep 60

      # 7. Supprime les ENIs disponibles dans le VPC
      for ENI_ID in $(aws ec2 describe-network-interfaces         --filters           "Name=vpc-id,Values=${self.triggers.vpc_id}"           "Name=status,Values=available"         --query "NetworkInterfaces[].NetworkInterfaceId"         --region ${self.triggers.aws_region}         --output text 2>/dev/null); do
        echo "Suppression ENI: $ENI_ID"
        aws ec2 delete-network-interface           --network-interface-id $ENI_ID           --region ${self.triggers.aws_region} 2>/dev/null || true
      done

      # 8. Supprime les SGs créés par le controller et l'ALB
      for SG_ID in $(aws ec2 describe-security-groups         --filters "Name=vpc-id,Values=${self.triggers.vpc_id}"         --query "SecurityGroups[?GroupName!='default'].GroupId"         --region ${self.triggers.aws_region}         --output text 2>/dev/null); do
        echo "Suppression SG: $SG_ID"
        aws ec2 delete-security-group           --group-id $SG_ID           --region ${self.triggers.aws_region} 2>/dev/null || true
      done

       # 9. Retire les finalizers du namespace monitoring
       kubectl patch namespace monitoring \
         -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true

       kubectl get namespace monitoring -o json 2>/dev/null | \
         python3 -c "import sys,json; d=json.load(sys.stdin); d['spec']['finalizers']=[]; print(json.dumps(d))" | \
         kubectl replace --raw /api/v1/namespaces/monitoring/finalize -f - 2>/dev/null || true

      echo "=== Cleanup terminé ==="
    EOF
  }

  depends_on = [
    helm_release.alb_controller,
    kubernetes_ingress_v1.preprod,
    kubernetes_ingress_v1.prod,
    kubernetes_namespace.preprod,
    kubernetes_namespace.prod
  ]
}