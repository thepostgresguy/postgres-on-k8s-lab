# Part 1: a production-like lab in 15 minutes

Blog post: *Postgres on Kubernetes: a production-like lab in 15 minutes* (Dec 2, 2026)

You'll build the lab the rest of the series uses: three Postgres instances, one per
zone, managed by CloudNativePG, plus a toolbox pod with psql, pgbench and pgtools.

```
kind cluster
├── zone-a  ─ pg-lab-1  (primary)
├── zone-b  ─ pg-lab-2  (replica)
├── zone-c  ─ pg-lab-3  (replica)
└── pgtools toolbox ──► pg-lab-rw (always the primary)
                    └─► pg-lab-ro (replicas only)
```

## 1. Create the Kubernetes cluster

```bash
make kind
kubectl get nodes -L topology.kubernetes.io/zone
```

kind runs each node as a Docker container. The zone labels make it behave like a
cloud cluster spread over three availability zones.

## 2. Install the operator

```bash
make operator
```

The operator is the piece that knows Postgres: it creates instances, sets up
replication, handles failover and runs backups. Kubernetes alone doesn't.

## 3. Create the Postgres cluster

```bash
make part-01
make status
```

Read [`cluster.yaml`](cluster.yaml) while it starts. The parts worth noticing:

- `instances: 3`, one primary and two streaming replicas.
- `requests` equal to `limits`, so the pods get Guaranteed QoS.
- `topologySpreadConstraints`, so each instance lands in a different zone.
- `pg_stat_statements` enabled from the start, because you'll want it the first time
  something is slow.

CloudNativePG also creates three Services: `pg-lab-rw` (primary), `pg-lab-ro` (replicas)
and `pg-lab-r` (any instance), and a `pg-lab-app` Secret with the app credentials.

## 4. Connect and load data

```bash
make load      # pgbench tables, scale 10
make psql
```

```sql
SELECT pg_is_in_recovery();            -- f: you're on the primary
SELECT client_addr, state, sync_state
FROM pg_stat_replication;              -- two replicas, streaming
```

## 5. Run pgtools against it

```bash
make bench                              # 60 seconds of load
make pgtools SCRIPT=top-queries.sql
make pgtools SCRIPT=cache-hit.sql
make pgtools SCRIPT=replication.sql
```

## 6. Check it

```bash
make test-part-01
```

This is the same check CI runs on every change.

## Clean up

```bash
make down
```

**Next:** Part 2 puts PgBouncer in front of this cluster and shows what your app sees
during a restart.
