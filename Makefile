.PHONY: lua_deps watch dev build check_untracked_files toc_check toc_update i18n_check i18n_fmt test-ci

# Variables
ROCKSBIN := $(HOME)/.luarocks/bin

lua_deps:
	@luarocks install busted --local
	@luarocks install luacov --local
	@luarocks install luacov-html --local

watch: check_untracked_files toc_check i18n_check
	@wow-build-tools build watch -t BeaconUnitFrames -r ./.release

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

i18n_check:
	@uv run .scripts/check_for_missing_locale_keys.py

i18n_fmt:
	@uv run .scripts/organize_translations.py

test-ci:
	@mkdir -p luacov-html
	@echo "No tests configured for BeaconUnitFrames"
