# Project Structure

```text
task-manager/
├── src/
│   ├── main/java/com/example/taskmanager/
│   │   ├── TaskManagerApplication.java  # Spring Boot entry point
│   │   ├── controller/                  # Task REST endpoints and /health
│   │   ├── service/                     # Small CRUD business layer
│   │   ├── repository/                  # Spring Data JPA repository
│   │   └── entity/                      # Task database entity
│   ├── main/resources/application.yml   # DB and Actuator configuration
│   └── test/                            # Spring context smoke test
├── pom.xml                              # Maven dependencies and Java 21 build
├── Dockerfile                           # Multi-stage, non-root application image
├── docker-compose.yml                   # API, PostgreSQL, Prometheus, Grafana
├── .dockerignore / .gitignore           # Small build context and secret protection
├── README.md                            # Setup, operations, concepts, troubleshooting
├── structure.md                         # This file
├── .github/workflows/
│   ├── ci.yml                           # Test, package, build, Trivy scan
│   └── cd.yml                           # Approved GitOps-style production deployment
├── k8s/
│   ├── configmap.yaml / secret.yaml     # Database non-secret and secret settings
│   ├── kustomization.yaml                # Reusable Kubernetes resource bundle
│   ├── postgres.yaml                    # Demo PostgreSQL, Service, and persistent data
│   ├── deployment.yaml / service.yaml   # API workload and cluster networking
│   ├── ingress.yaml                     # /api and /health routing
│   └── hpa.yaml                         # CPU-based API autoscaling
├── helm/task-manager/
│   ├── Chart.yaml / values.yaml          # Chart metadata and configurable values
│   └── templates/                       # API Deployment, Service, HPA, ConfigMap, Secret, Ingress
├── kustomize/
│   ├── base/                            # Shared Kubernetes resources
│   └── overlays/dev|prod/               # Environment-specific replica counts
├── terraform/main.tf                    # Docker network, volume, and PostgreSQL demo IaC
├── ansible/setup.yml                    # Safe host directory and Compose-config setup
└── monitoring/
    ├── prometheus.yml                   # Actuator metrics scrape configuration
    └── grafana/
        ├── dashboard.json               # Request/JVM metrics dashboard
        └── provisioning/                # Automatic Prometheus and dashboard setup
```

## Concept-to-code map

| Concept | Files demonstrating it |
|---|---|
| REST API and database | `src/`, `pom.xml`, `application.yml` |
| Docker and Compose | `Dockerfile`, `docker-compose.yml` |
| CI/CD, GitOps, and vulnerability scan | `.github/workflows/ci.yml`, `.github/workflows/cd.yml` |
| Kubernetes and scaling | `k8s/deployment.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml` |
| Helm and Kustomize | `helm/`, `kustomize/` |
| IaC and configuration management | `terraform/main.tf`, `ansible/setup.yml` |
| Observability and SRE | `monitoring/`, Actuator configuration, `README.md` |
