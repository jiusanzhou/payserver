# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif


WD := $(shell pwd)
GOPATH := $(shell go env GOPATH)
LDFLAGS := $(shell go run go.zoe.im/x/version/gen)
TAG := $(shell go run go.zoe.im/x/version/gen -v)

BUILD_LDFLAGS := $(LDFLAGS)

# Parse the build tag from ldflags
TAG := $(shell echo $(LDFLAGS) | awk '{print $$2}' | awk -F '=' '{print $$2}' | sed s/+/-/)

default: main

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# # Build UI
# webui:
#	   export GENERATE_SOURCEMAP=false && cd ui && yarn build
#	   go generate ./ui

# Build manager binary, # --ldflags '-linkmode external -w -extldflags "-static"'
# -w -s
main: fmt vet
	CGO_ENABLED=1 go build --ldflags '$(BUILD_LDFLAGS) -w -s' -o dist/payserver .