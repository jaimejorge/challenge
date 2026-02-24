.PHONY: install lint test argocd-info grafana-info postgresql-info clean help docker-build run tls trust-ca kubeconfig download-dashboard check

include .env
export

SCRIPTS_DIR := scripts

help:
	@echo "Available targets:"
	@echo "  docker-build  - Force rebuild Docker image"
	@echo "  run           - Run interactive shell in Docker"
	@echo "  install       - Install kind cluster with ArgoCD"
	@echo "  tls           - Setup TLS certificates (runs in Docker)"
	@echo "  trust-ca      - Trust CA on host machine (runs on host)"
	@echo "  kubeconfig    - Export kubeconfig to use with local kubectl"
	@echo "  test/lint     - Run ShellCheck + Helm lint"
	@echo "  argocd-info   - Show ArgoCD URL, username and password"
	@echo "  grafana-info  - Show Grafana URL, username and password"
	@echo "  postgresql-info - Show PostgreSQL connection info"
	@echo "  download-dashboard ID=<id> - Download a Grafana dashboard from grafana.com"
	@echo "  check         - Check cluster and apps status, diagnose issues"
	@echo "  clean         - Delete the kind cluster"
	@echo ""

docker-build:
	@$(SCRIPTS_DIR)/docker-build.sh 

install:
	@$(SCRIPTS_DIR)/run.sh ./scripts/cluster_install.sh

# Lint (alias for test)
lint: test

test:
	@$(SCRIPTS_DIR)/run.sh ./scripts/test.sh

argocd-info:
	@$(SCRIPTS_DIR)/run.sh ./scripts/info_argocd.sh

grafana-info:
	@$(SCRIPTS_DIR)/run.sh ./scripts/info_grafana.sh

postgresql-info:
	@$(SCRIPTS_DIR)/run.sh ./scripts/info_postgresql.sh

download-dashboard:
	@$(SCRIPTS_DIR)/run.sh ./scripts/grafana_download-dashboard.sh $(ID)  $(NAME)

clean:
	@$(SCRIPTS_DIR)/run.sh ./scripts/cluster_clean.sh

tls:
	@$(SCRIPTS_DIR)/run.sh ./scripts/cluster_setup_tls.sh

trust-ca:
	@$(SCRIPTS_DIR)/trust-ca.sh

kubeconfig:
	@$(SCRIPTS_DIR)/kubeconfig.sh

check:
	@$(SCRIPTS_DIR)/run.sh ./scripts/cluster_check.sh
