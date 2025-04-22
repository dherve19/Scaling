$resourceGroupName = "clustertest1-RG"
$location = "eastus"
$aksClusterName = "Clustertest1"
$namespace = "autoscale-test"
$deploymentName = "sample-app"
$serviceName = "sample-app-service"
$hpaName = "sample-app-autoscaler"
$cpuThreshold = 50
$minReplicas = 2
$maxReplicas = 5
az account set --subscription "9cd66aea-edf8-4892-affb-476e5bffd732" #replace with the suscription
# Add Horizontal Pod Autoscaler
Write-Host "Configuring Horizontal Pod Autoscaler for deployment: $deploymentName..."
$hpaManifest = @"
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $hpaName
  namespace: $namespace
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $deploymentName
  minReplicas: $minReplicas
  maxReplicas: $maxReplicas
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: $cpuThreshold
"@
$hpaManifest | kubectl apply -f -

Write-Host "Horizontal Pod Autoscaler has been configured successfully."
