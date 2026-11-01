# Baby Piano Pop (Godot 4.7.2) — quick launch. `make` or `make help` lists targets.
.DEFAULT_GOAL := help
GODOT ?= godot
APK := build/BabyPianoPop.apk

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

run: ## Run the game in the Godot window
	$(GODOT) --path .

dev: run ## Alias for run

import: ## Import assets and parse all scripts
	$(GODOT) --headless --path . --import

test: ## Run headless logic tests
	$(GODOT) --headless --path . -s tests/run_tests.gd

apk: ## Export a debug APK to build/
	@mkdir -p build
	$(GODOT) --headless --path . --export-debug "Android" $(APK)

install: ## Install build/BabyPianoPop.apk on the connected device
	adb install -r $(APK)

typecheck: ## Import + boot headless; fail on any ERROR line
	@out=$$($(GODOT) --headless --path . --import 2>&1; $(GODOT) --headless --path . --quit-after 120 2>&1); \
	echo "$$out"; ! echo "$$out" | grep -q 'ERROR'

lint: typecheck ## No GDScript linter configured; runs typecheck

check: ## Run every ActionPlan gate
	@node .actionplan/scripts/check.cjs

status: ## Board + Mirror
	@node .actionplan/scripts/status.cjs

qa: ## List QA evidence folders
	@ls -1t .actionplan/qa 2>/dev/null || echo "no QA runs yet"

.PHONY: help run dev import test apk install typecheck lint check status qa
