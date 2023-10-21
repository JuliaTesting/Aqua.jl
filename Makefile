all: generate_badge generate_favicon

.PHONY: all generate_badge generate_favicon

generate_badge:
	SVG_BASE64=$(shell base64 -w 0 docs/src/assets/logo.svg); \
	curl -o "badge.svg" "https://img.shields.io/badge/tested_with-Aqua.jl-05C3DD.svg?logo=data:image/svg+xml;base64,$$SVG_BASE64"

generate_favicon:
	convert -background none docs/src/assets/logo.svg -resize 256x256 -gravity center -extent 256x256 logo.png
	convert logo.png -define icon:auto-resize=256,64,48,32,16 docs/src/assets/favicon.ico
	rm logo.png
