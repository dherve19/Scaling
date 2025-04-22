# Variables
$testerNamespace = "stress-load-testing"
$testerName = "k6-tester"
$externalIP = "48.217.133.131" # Replace with your actual LoadBalancer external IP

# Ensure the namespace exists
Write-Host "Ensuring the namespace: $testerNamespace is created..."
$namespaceExists = kubectl get namespace $testerNamespace --ignore-not-found
if (-not $namespaceExists) {
    Write-Host "Namespace $testerNamespace not found. Creating it now..."
    kubectl create namespace $testerNamespace
} else {
    Write-Host "Namespace $testerNamespace already exists."
}

# Define the K6 test script content
Write-Host "Defining K6 test script with 5000000 users..."
$k6Script = @"
import http from 'k6/http';
import { sleep } from 'k6';

// Options for the test
export const options = {
    stages: [
        { duration: '5m', target: 5000000 }, // Ramp-up to 5000000 users over 5 minute
        { duration: '10m', target: 5000000}, // Sustain 5000000 users for 10 minutes
        { duration: '1m', target: 200 },   // Ramp-down to 100 users over 1 minute
    ],
};

export default function () {
    http.get('http://$externalIP:80'); // Replace $externalIP with your LoadBalancer IP
    sleep(1); // Simulate a delay between requests
}
"@

# Delete the existing ConfigMap (if it exists)
Write-Host "Deleting existing ConfigMap (if any)..."
kubectl delete configmap k6-test-script -n $testerNamespace --ignore-not-found

# Create a new ConfigMap with the updated K6 test script
Write-Host "Creating ConfigMap with new K6 test script..."
kubectl create configmap k6-test-script -n $testerNamespace --from-literal=test.js="$k6Script"

# Deploy the K6 load tester pod
Write-Host "Deploying K6 load tester pod: $testerName..."
$k6Manifest = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $testerName
  namespace: $testerNamespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $testerName
  template:
    metadata:
      labels:
        app: $testerName
    spec:
      containers:
      - name: $testerName
        image: ghcr.io/grafana/k6:latest
        command: ["k6", "run", "/scripts/test.js"]
        volumeMounts:
        - mountPath: /scripts
          name: test-script
      volumes:
      - name: test-script
        configMap:
          name: k6-test-script
"@
$k6Manifest | kubectl apply -f -

# Verify the deployment status
Write-Host "Verifying deployment status for K6 load tester pod..."
kubectl get pods -n $testerNamespace
