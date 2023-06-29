
PROJECT := terraform-aws-secure-for-cloud
GO_BIN := $(shell go env GOPATH)/bin
TFLINT := $(GO_BIN)/tflint
DOCKER ?= docker
MOTO_VERSION := 4.1.7

SHELL := /bin/bash

$(TFLINT): export TMPDIR = $(shell mktemp -d)
$(TFLINT):
	curl -sL https://github.com/terraform-linters/tflint/releases/latest/download/tflint_$(shell go env GOHOSTOS)_$(shell go env GOHOSTARCH).zip -o $${TMPDIR}/tflint.zip
	unzip $${TMPDIR}/tflint.zip -d $(GO_BIN) tflint
	rm -rf $${TMPDIR}

deps: $(TFLINT)
	go install github.com/terraform-docs/terraform-docs@v0.16.0
	go install github.com/hashicorp/terraform-config-inspect@latest

lint: $(TFLINT)
	$(MAKE) -C modules lint

fmt:
	terraform fmt -check -recursive modules

clean:
	find -name ".terraform" -type d | xargs rm -rf
	find -name ".terraform.lock.hcl" -type f | xargs rm -f

.PHONY: test
test:
	$(MAKE) -C test test
