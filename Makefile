include versions.env

KIND_CLUSTER  ?= pg-k8s-lab
CNPG_MANIFEST := https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v$(CNPG_VERSION)/cnpg-$(CNPG_VERSION).yaml
SCRIPT        ?= top-queries.sql

.DEFAULT_GOAL := help
.PHONY: help up kind operator part-01 load bench psql pgtools status test-part-01 check-pins down

help: ## Show the available targets
	@grep -hE '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

up: kind operator part-01 ## Create everything for Part 1 in one go

kind: ## Create the kind cluster (1 control plane, 3 workers in 3 zones)
	kind create cluster --name $(KIND_CLUSTER) --image $(KIND_NODE_IMAGE) --config kind/cluster.yaml --wait 2m

operator: ## Install the CloudNativePG operator
	kubectl apply --server-side -f $(CNPG_MANIFEST)
	kubectl -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=5m

part-01: ## Part 1: a three-instance Postgres cluster plus the pgtools toolbox
	scripts/retry.sh 12 10 kubectl apply -f 01-lab-setup/cluster.yaml
	kubectl wait cluster/pg-lab --for=condition=Ready --timeout=10m
	kubectl apply -f 01-lab-setup/toolbox.yaml
	kubectl rollout status deployment/pgtools --timeout=5m

load: ## Create pgbench tables (scale 10, about 160 MB)
	kubectl exec deploy/pgtools -- pgbench -i -s 10

bench: ## Run 60 seconds of pgbench load
	kubectl exec deploy/pgtools -- pgbench -c 10 -j 2 -T 60 -P 10

psql: ## Open psql on the primary from the toolbox pod
	kubectl exec -it deploy/pgtools -- psql

pgtools: ## Run a pgtools script, e.g. make pgtools SCRIPT=activity.sql
	kubectl exec deploy/pgtools -- psql -X -f $(SCRIPT)

status: ## Show the cluster and where each instance runs
	kubectl get cluster pg-lab
	kubectl get pods -l cnpg.io/podRole=instance -L cnpg.io/instanceRole -o wide

test-part-01: ## Check that Part 1 works end to end
	tests/part-01.sh

check-pins: ## Check that the manifests match versions.env
	scripts/check-pins.sh

down: ## Delete the kind cluster and everything in it
	kind delete cluster --name $(KIND_CLUSTER)
