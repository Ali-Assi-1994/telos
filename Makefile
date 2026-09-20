SHELL := /bin/bash

.PHONY: get build_runner_build build_runner_watch test analyze format format_check integration_test

get:
	@if [ ! -f .env.dev ]; then \
		cp .env.example .env.dev; \
		echo "Created .env.dev from .env.example -- fill in real Supabase values before running the app."; \
	fi
	flutter pub get

build_runner_build:
	dart run build_runner build

build_runner_watch:
	dart run build_runner watch

test:
	flutter test --coverage

analyze:
	dart analyze

format:
	dart format .

format_check:
	dart format --output none --set-exit-if-changed .

# Runs all integration_test/ flows with Patrol on a booted simulator/emulator
# or connected device. Requires patrol_cli 4.6.1 (see docs/testing-strategy.md).
# Usage: make integration_test DEVICE="iPhone 16e"
integration_test:
	patrol test -d "$(DEVICE)"

