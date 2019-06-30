.PHONY: \
    clean \
    deps \
    pbgo \
    swagger

red    = /bin/echo -e "\x1b[31m\#\# $1\x1b[0m"
green  = /bin/echo -e "\x1b[32m\#\# $1\x1b[0m"
yellow = /bin/echo -e "\x1b[33m\#\# $1\x1b[0m"
blue   = /bin/echo -e "\x1b[34m\#\# $1\x1b[0m"
pink   = /bin/echo -e "\x1b[35m\#\# $1\x1b[0m"
cyan   = /bin/echo -e "\x1b[36m\#\# $1\x1b[0m"

PROTOS := $(shell find apis/proto -maxdepth 1 -type f -regex ".*\.proto")
PBGOS = $(PROTOS:apis/proto/%.proto=apis/generated/%.pb.go)
SWAGGERS = $(PROTOS:apis/proto/%.proto=apis/swagger/%.swagger.json)

define go-get
	GO111MODULE=off go get -u $1
endef

define mkdir
	mkdir -p $1
endef

define protoc-gen
	protoc \
		-I ./apis/proto \
		-I $(GOPATH)/src/github.com/protocolbuffers/protobuf/src \
		-I $(GOPATH)/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		$1 \
		./apis/proto/*.proto
endef

all: \
    pbgo \
    swagger

pbgo: $(PBGOS)
swagger: $(SWAGGERS)

clean:
	rm -rf apis/generated apis/swagger

deps: \
    $(GOPATH)/src/github.com/protocolbuffers/protobuf \
    $(GOPATH)/src/github.com/golang/protobuf/protoc-gen-go \
    $(GOPATH)/src/github.com/gogo/protobuf/protoc-gen-gofast \
    $(GOPATH)/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
    $(GOPATH)/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger

$(GOPATH)/src/github.com/protocolbuffers/protobuf:
	git clone \
	    --depth 1 \
	    https://github.com/protocolbuffers/protobuf \
	    $(GOPATH)/src/github.com/protocolbuffers/protobuf

$(GOPATH)/src/github.com/golang/protobuf/protoc-gen-go:
	$(call go-get, github.com/golang/protobuf/protoc-gen-go)

$(GOPATH)/src/github.com/gogo/protobuf/protoc-gen-gofast:
	$(call go-get, github.com/gogo/protobuf/protoc-gen-gofast)

$(GOPATH)/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway:
	$(call go-get, github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway)

$(GOPATH)/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger:
	$(call go-get, github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger)

apis/generated:
	$(call mkdir, ./apis/generated)

apis/swagger:
	$(call mkdir, ./apis/swagger)

$(PBGOS): deps apis/generated
	@$(call green, "generating pb.go files...")
	$(call protoc-gen, --gofast_out=./apis/generated)

$(SWAGGERS): deps apis/swagger
	@$(call green, "generating swagger.json files...")
	$(call protoc-gen, --swagger_out=json_names_for_fields=true:./apis/swagger)
