#!/bin/bash

cd "/run/media/srinath/New Volume/Internship proj" || exit 1

echo "========================================"
echo " STARTING TASK MANAGER"
echo "========================================"

docker compose up -d --build

echo ""
echo "Waiting for services..."
sleep 5

echo ""
echo "========================================"
echo " TASK MANAGER IS RUNNING"
echo "========================================"
echo ""
echo "Frontend   : http://localhost:8081"
echo "API        : http://localhost:8080"
echo "Health     : http://localhost:8080/health"
echo "Prometheus : http://localhost:9090"
echo "Grafana    : http://localhost:3000"
echo ""
echo "========================================"

docker compose ps
