infra-plan:
	@cd infra/live && terragrunt run-all plan --terragrunt-non-interactive

infra-apply:
	@cd infra/live && terragrunt run-all apply --terragrunt-non-interactive

server-and-nodes: infra-apply
	@sh ./scripts/server-and-workers.sh

monitoring: server-and-nodes
	@sh ./scripts/monitoring.sh

apps: monitoring
	@sh ./scripts/app.sh

grafana_scripts: apps
	@sh ./scripts/grafana_scripts.sh

deploy-env-final: grafana_scripts