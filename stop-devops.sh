#!/bin/bash

echo "========================================"
echo " STOPPING TASK MANAGER DEVOPS"
echo "========================================"

echo "===== STOP PROMETHEUS PORT-FORWARD ====="
pkill -f "kubectl port-forward svc/prometheus 9090:9090" 2>/dev/null || true

echo "===== STOP GRAFANA PORT-FORWARD ====="
pkill -f "kubectl port-forward svc/grafana 3000:3000" 2>/dev/null || true

echo "===== STOP MINIKUBE ====="
if minikube status >/dev/null 2>&1; then
    minikube stop
else
    echo "Minikube is already stopped."
fi

echo "========================================"
echo " TASK MANAGER DEVOPS STOPPED"
echo "========================================"
