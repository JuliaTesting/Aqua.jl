JULIA:=julia

default: help

.PHONY: default changelog docs docs-instantiate generate_badge generate_favicon help test

docs-instantiate:
	${JULIA} docs/instantiate.jl

changelog: docs-instantiate
	${JULIA} --project=docs docs/changelog.jl

docs: docs-instantiate
	${JULIA} --project=docs docs/make.jl

generate_badge:
	SVG_BASE64=$(shell base64 -w 0 docs/src/assets/logo.svg); \
	curl -o "badge.svg" "https://img.shields.io/badge/tested_with-Aqua.jl-05C3DD.svg?logo=data:image/svg+xml;base64,$$SVG_BASE64"

generate_favicon:
	convert -background none docs/src/assets/logo.svg -resize 256x256 -gravity center -extent 256x256 logo.png
	convert logo.png -define icon:auto-resize=256,64,48,32,16 docs/src/assets/favicon.ico
	rm logo.png

test:
	${JULIA} --project -e 'using Pkg; Pkg.test()'

help:
	@echo "The following make commands are available:"
	@echo " - make changelog: update all links in CHANGELOG.md's footer"
	@echo " - make docs: build the documentation"
	@echo " - make generate_badge: generate the Aqua.jl badge"
	@echo " - make generate_favicon: generate the Aqua.jl favicon"
	@echo " - make test: run the tests"
