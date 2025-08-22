#!/bin/bash

# Get app URL
EXTERNAL_IP=$(kubectl get service nodejs-app -n nodejs-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$EXTERNAL_IP" ]; then
    echo "No external IP found"
    exit 1
fi

APP_URL="http://$EXTERNAL_IP"
echo "Testing: $APP_URL"

# Check for Apache Bench
if ! command -v ab &> /dev/null; then
    echo "Install Apache Bench: brew install httpd"
    exit 1
fi

echo "Starting load test (Press Ctrl+C to stop)..."

# Show status before test
kubectl get pods -n nodejs-app -l app.kubernetes.io/name=nodejs-app
kubectl get hpa -n nodejs-app

# Cleanup on exit
trap 'echo "Stopping..."; kubectl get hpa -n nodejs-app; kubectl get pods -n nodejs-app -l app.kubernetes.io/name=nodejs-app; exit' INT

# Monitor status every 10 seconds
while true; do
    sleep 10 &
    ab -n 500 -c 20 "$APP_URL/cpu-load" > /dev/null 2>&1 &
    ab -n 300 -c 15 "$APP_URL/" > /dev/null 2>&1 &
    wait
    echo "$(date +%H:%M:%S) - $(kubectl get hpa -n nodejs-app --no-headers | awk '{print "CPU:" $3 " Pods:" $6"/"$7"/"$8}')"
done