# applet — quick launch. `make` or `make help` lists targets.
.DEFAULT_GOAL := help

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

dev: ## Run the dev server
	npm run dev

test: ## Run tests (target a file: make test ARGS=path)
	echo 'TODO(verify): test command'; exit 1

lint: ## Lint
	npm run lint

typecheck: ## Typecheck
	echo 'TODO(verify): typecheck command'; exit 1

check: ## Run every ActionPlan gate
	@node .actionplan/scripts/check.cjs

status: ## Board + Mirror
	@node .actionplan/scripts/status.cjs

qa: ## List QA evidence folders
	@ls -1t .actionplan/qa 2>/dev/null || echo "no QA runs yet"

.PHONY: help dev test lint typecheck check status qa
