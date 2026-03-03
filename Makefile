.PHONY: help get analyze clean build-android build-android-debug build-aab install run-android run-windows apk-path

help: ## List all available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

get: ## Install Flutter dependencies
	flutter pub get

analyze: ## Run Flutter static analysis
	flutter analyze

clean: ## Clean Flutter build artifacts
	flutter clean

build-android: ## Build release APK for Android
	flutter build apk --release

build-android-debug: ## Build debug APK for Android
	flutter build apk --debug

build-aab: ## Build release Android App Bundle
	flutter build appbundle

install: ## Install APK on connected Android device
	flutter install

run-android: ## Run on connected Android device
	flutter run -d android

run-windows: ## Run on Windows
	flutter run -d windows

apk-path: ## Show path of the generated APK
	@echo "Release APK: build/app/outputs/flutter-apk/app-release.apk"
	@echo "Debug APK:   build/app/outputs/flutter-apk/app-debug.apk"
