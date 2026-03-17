SHELL := /bin/bash

.PHONY: get build_runner_build build_runner_watch test analyze

get:
	flutter pub get

build_runner_build:
	dart run build_runner build --delete-conflicting-outputs

build_runner_watch:
	dart run build_runner watch --delete-conflicting-outputs

test:
	flutter test

analyze:
	flutter analyze

