.PHONY: lua_deps watch dev build check_untracked_files toc_check toc_update i18n_check i18n_fmt wbt_setup test-ci

# Variables
ROCKSBIN := $(HOME)/.luarocks/bin
WBT_REF ?= v1-beta
WBT_DIR := ../wow-build-tools

lua_deps:
	@luarocks install busted --local
	@luarocks install luacov --local
	@luarocks install luacov-html --local

watch: check_untracked_files toc_check i18n_check
	@wow-build-tools build watch -t BeaconUnitFrames -r ./.release --force-alpha

dev: check_untracked_files toc_check i18n_check
	@wow-build-tools build -d -t BeaconUnitFrames -r ./.release --skipChangelog

build: check_untracked_files toc_check i18n_check
	@wow-build-tools build -d -t BeaconUnitFrames -r ./.release

toc_check:
	@wow-build-tools toc check \
		-a BeaconUnitFrames \
		-x libs/index.xml \
		--no-splash \
		-b -p

toc_update:
	@wow-build-tools toc update \
		-a BeaconUnitFrames \
		--no-splash \
		-b -p

check_untracked_files:
	@if [ -n "$$(git ls-files --others --exclude-standard)" ]; then \
		echo "You have untracked files:"; \
		git ls-files --others --exclude-standard; \
		echo ""; \
		echo "This may cause errors in game. Please stage or remove them."; \
		exit 1; \
	else \
		echo "No untracked files."; \
	fi

wbt_setup:
	@if [ ! -d "$(WBT_DIR)/scripts/i18n" ]; then \
		echo "Cloning wow-build-tools at ref $(WBT_REF)..."; \
		git clone --depth 1 -b "$(WBT_REF)" \
			https://github.com/McTalian-WoW-Addons/wow-build-tools "$(WBT_DIR)"; \
	else \
		echo "$(WBT_DIR) already set up."; \
	fi

i18n_check: wbt_setup
	@uv run --project $(WBT_DIR)/scripts/i18n \
		$(WBT_DIR)/scripts/i18n/check_for_missing_locale_keys.py \
		--addon-dir BeaconUnitFrames \
		--locale-dir BeaconUnitFrames/locale

i18n_fmt: wbt_setup
	@uv run --project $(WBT_DIR)/scripts/i18n \
		$(WBT_DIR)/scripts/i18n/organize_translations.py \
		--locale-dir BeaconUnitFrames/locale

test-ci:
	@mkdir -p luacov-html
	@echo "No tests configured for BeaconUnitFrames"
