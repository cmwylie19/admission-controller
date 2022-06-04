# Makefile for building the Admission Controller server + docker image.

.DEFAULT_GOAL := docker-image

IMAGE ?= cmwylie19/admission-controller:latest

image/webhook-server: $(shell find . -name '*.go')
	GOARCH=arm64 CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o $@ ./cmd/webhook-server

.PHONY: docker-image
docker-image: image/webhook-server
	docker build -t $(IMAGE) image/

.PHONY: push-image
push-image: docker-image
	docker push $(IMAGE)
