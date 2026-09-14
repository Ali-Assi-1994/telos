SHELL := /bin/bash

.PHONY: get build_runner_build build_runner_watch test analyze

get:
	@if [ ! -f .env.dev ]; then \
		cp .env.example .env.dev; \
		echo "Created .env.dev from .env.example -- fill in real Supabase values before running the app."; \
	fi
	flutter pub get

build_runner_build:
	dart run build_runner build --delete-conflicting-outputs

build_runner_watch:
	dart run build_runner watch --delete-conflicting-outputs

test:
	flutter test

analyze:
	flutter analyze

