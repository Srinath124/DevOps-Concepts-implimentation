# SRE – Task Manager API

## SLIs

### Availability
Successful HTTP requests / total HTTP requests.

### Error Rate
HTTP 5xx responses / total HTTP responses.

### Latency
95th percentile HTTP response latency.

### Resource Usage
JVM memory usage and Kubernetes CPU utilization.

## SLOs

| SLI | SLO |
|---|---|
| Availability | >= 99% |
| 5xx Error Rate | < 1% |
| P95 Latency | < 500 ms |
| Kubernetes CPU | < 70% sustained |

## Error Budget

For a 99% availability SLO:

- Monthly window: 30 days
- Allowed unavailability: 1%
- Error budget: approximately 7 hours 12 minutes

## Monitoring

Prometheus collects application metrics from:

`/actuator/prometheus`

Grafana visualizes:

- Request rate
- Request count
- P95 response time
- Error rate
- JVM memory
- CPU, pod count, and application health when Kubernetes metrics are available

## Response

When an SLO is violated:

1. Check Grafana metrics.
2. Check Kubernetes pod health.
3. Check application logs.
4. Check PostgreSQL health.
5. Investigate the cause.
6. Restore service.
7. Record the incident and corrective action.

## Failure scenarios and recovery

### Database failure

The UI reports `DATABASE UNAVAILABLE` for failed 5xx/database calls and its system indicator goes offline. Check the PostgreSQL Pod, Service, PVC binding, credentials, and PostgreSQL logs. Restore the database Pod or credentials, wait for API readiness, then verify existing tasks with `GET /api/tasks`. Do not delete the PVC during recovery.

### API failure

The UI reports `API CONNECTION LOST` and preserves no unsaved task mutations. Check ingress endpoints, API readiness/liveness, application logs, and the database dependency. Correct the failure, roll out the API, and validate `/health`, `/actuator/health`, and `/api/tasks`.

### Pod restart and durable data

API Pods are stateless; task data remains in PostgreSQL. PostgreSQL mounts the `postgres-data` PVC, so a replacement Pod mounts the same data volume. Follow the durable-data verification procedure in the README after any storage or cluster configuration change. No durability result is assumed without executing that procedure.
