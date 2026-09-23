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

## Response

When an SLO is violated:

1. Check Grafana metrics.
2. Check Kubernetes pod health.
3. Check application logs.
4. Check PostgreSQL health.
5. Investigate the cause.
6. Restore service.
7. Record the incident and corrective action.
