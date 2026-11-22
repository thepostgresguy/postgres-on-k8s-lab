# Postgres on Kubernetes: the lab

[![lab](https://github.com/thepostgresguy/postgres-on-k8s-lab/actions/workflows/lab.yml/badge.svg)](https://github.com/thepostgresguy/postgres-on-k8s-lab/actions/workflows/lab.yml)

Run every demo from the **Postgres on Kubernetes** series on your laptop: a local
[kind](https://kind.sigs.k8s.io/) cluster, the [CloudNativePG](https://cloudnative-pg.io/)
operator and a three-instance Postgres cluster you can break on purpose.

It starts from [PostgreSQL in Kubernetes?!?!? are you serious?](https://thepostgresguy.com/blog/postgresql-in-kubernetes-are-you-serious/)
and turns each challenge in that post into something you can run.

## Quick start

```bash
git clone https://github.com/thepostgresguy/postgres-on-k8s-lab.git
cd postgres-on-k8s-lab
make up load        # kind cluster + operator + Postgres + toolbox + pgbench data
make status         # where each instance runs, and which one is primary
make pgtools        # run a pgtools script against the primary
make down           # delete everything
```

`make help` lists every target.

**You need:** Docker (or Podman), [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
`v0.33.0`, `kubectl` and `make`. Give Docker about 4 CPUs and 8 GB of memory.

## The series

Each part has its own folder and a git tag (`part-01`, `part-02`…). The links in each
blog post point to that part's tag, so they keep working as the repo changes.

| Part | Folder | Topic | Blog post |
| --- | --- | --- | --- |
| 1 | [`01-lab-setup`](01-lab-setup/) | A production-like lab in 15 minutes | Dec 2, 2026 |
| 2 | `02-pooler` | PgBouncer with the CloudNativePG Pooler | Coming Dec 16 |
| 3 | `03-backups-pitr` | Backups and point-in-time recovery | Coming Jan 6 |
| 4 | `04-failover` | Kill the primary: a failover drill | Coming Jan 13 |
| 5 | `05-monitoring` | Monitoring without a SaaS bill | Coming Jan 20 |
| 6 | `06-storage` | StorageClass, IOPS and stranded pods | Coming Feb 10 |
| 7 | `07-resources` | shared_buffers vs. the pod memory limit | Coming Feb 24 |
| 8 | `08-upgrades` | Minor and major upgrades | Coming Mar 10 |
| 9 | `09-security` | Locking down Postgres on Kubernetes | Coming Mar 24 |
| 10 | `10-operators` | CloudNativePG vs. Zalando Postgres Operator | Coming Apr 7 |
| 11 | `11-gotchas` | 10 gotchas I learned the hard way | Coming Apr 21 |

## pgtools inside the cluster

The lab runs a `pgtools` toolbox pod next to the database, with psql, pgbench and every
script from [pgtools](https://github.com/thepostgresguy/pgtools) at a pinned commit.
That is how you would debug a real cluster: from inside it, with scripts you trust.

```bash
make pgtools SCRIPT=activity.sql
make pgtools SCRIPT=monitoring/replication.sql
make psql
```

## Pinned versions

Kubernetes tutorials stop working because something upstream moves. Every version is
pinned in [`versions.env`](versions.env), and CI runs the lab every week to catch drift.

| Component | Version |
| --- | --- |
| kind | v0.33.0 |
| Kubernetes (kind node) | v1.37.0 |
| CloudNativePG | 1.30.2 |
| PostgreSQL | 18.7 (`ghcr.io/cloudnative-pg/postgresql:18.7-system-trixie`) |
| pgtools | `d331a8b` |

To upgrade, change `versions.env` and the manifests, then run `make check-pins`.

## Ask and contribute

Something broke, or you want a topic covered? [Open an issue](https://github.com/thepostgresguy/postgres-on-k8s-lab/issues).
War stories about running Postgres on Kubernetes are welcome too.

## License and disclaimer

[Apache 2.0](LICENSE). This is a personal project: the views and code are my own and not
those of my employer. The lab is for learning. Don't point it at production data.
