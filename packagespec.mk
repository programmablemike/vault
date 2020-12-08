# ***
# WARNING: Do not EDIT or MERGE this file, it is generated by packagespec.
# ***
# packagespec.mk should be included at the end of your main Makefile,
# it provides hooks into packagespec targets, so you can run them
# from the root of your product repository.
#
# All packagespec-generated make targets assume they are invoked by
# targets in this file, which provides the necessary context for those
# other targets. Therefore, this file is not just for conveninence but
# is currently necessary to the correct functioning of Packagespec.

# Since this file is included in other Makefiles, which may or may not want
# to use bash with these options, we explicitly set the shell for specific
# targets, in this file, rather than setting the global SHELL variable.
PACKAGESPEC_SHELL := /usr/bin/env bash -euo pipefail -c

# The RUN macro is used in place of the shell builtin in this file, so that
# we can use the PACKAGESPEC_SHELL rather than the default from the Makefile
# that includes this one.
RUN = $(shell $(PACKAGESPEC_SHELL) '$1')

# This can be overridden by the calling Makefile to write config to a different path.
PACKAGESPEC_CIRCLECI_CONFIG ?= .circleci/config.yml
PACKAGESPEC_HOOK_POST_CI_CONFIG ?= echo > /dev/null

SPEC_FILE_PATTERN := packages*.yml
# SPEC is the human-managed description of which packages we are able to build.
SPEC := $(call RUN,find . -mindepth 1 -maxdepth 1 -name '$(SPEC_FILE_PATTERN)')
ifneq ($(words $(SPEC)),1)
$(error Found $(words $(SPEC)) $(SPEC_FILE_PATTERN) files, need exactly 1: $(SPEC))
endif
SPEC_FILENAME := $(notdir $(SPEC))
SPEC_MODIFIER := $(SPEC_FILENAME:packages%.yml=%)
# LOCKDIR contains the lockfile and layer files.
LOCKDIR  := packages$(SPEC_MODIFIER).lock
LOCKFILE := $(LOCKDIR)/pkgs.yml

export PACKAGE_SPEC_ID LAYER_SPEC_ID PRODUCT_REVISION PRODUCT_VERSION

# PASSTHROUGH_TARGETS are convenience aliases for targets defined in $(LOCKDIR)/Makefile
PASSTHROUGH_TARGETS := \
	build package-contents copy-package-contents build-all \
	aliases meta package package-meta package-meta-all \
	build-ci watch-ci \
	stage-config stage custom-build custom-build-config\
	bundle \
	orchestrator stop-orchestrator \
	list-custom-builds \
	list-staged-builds \
	list-promoted-builds \
	publish-config publish \
	workflow

.PHONY: $(PASSTHROUGH_TARGETS)

LOCAL_TARGETS := packages packagespec-circleci-config $(PACKAGESPEC_CIRCLECI_CONFIG)

# Set the shell for all packagespec targets.
$(PASSTHROUGH_TARGETS) $(LOCAL_TARGETS): SHELL := $(PACKAGESPEC_SHELL)

$(PASSTHROUGH_TARGETS):
	@PRODUCT_REPO_ROOT="$(call RUN,git rev-parse --show-toplevel)" $(MAKE) -C $(LOCKDIR) $@

# packages regenerates build and CI config using packagespec. This is only for
# internal HashiCorp use, as it has dependencies not available externally.
.PHONY: packages
packages:
	@command -v packagespec > /dev/null 2>&1 || { \
		echo "Please install packagespec."; \
		echo "Note: packagespec is only available to HashiCorp employees at present."; \
		exit 1; \
	}
	@packagespec lock -circleciconfig="$(PACKAGESPEC_CIRCLECI_CONFIG)"
	@$(MAKE) packagespec-circleci-config

packagespec-circleci-config:
	@$(PACKAGESPEC_HOOK_POST_CI_CONFIG)
