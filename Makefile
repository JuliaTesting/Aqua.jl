create_badge:
	SVG_BASE64=$(shell base64 -w 0 docs/src/assets/logo.svg); \
	curl -o "badge.svg" "https://img.shields.io/badge/tested_with-Aqua.jl-05C3DD.svg?logo=data:image/svg+xml;base64,$$SVG_BASE64"

create_favicon:
	convert -background none docs/src/assets/logo.svg -resize 256x256 logo.png
	convert logo.png -gravity center -background none -extent 256x256 logo256.png
	convert logo256.png -resize 16x16 logo16.png
	convert logo256.png -resize 32x32 logo32.png
	convert logo256.png -resize 48x48 logo48.png
	convert logo16.png logo32.png logo48.png logo256.png docs/src/assets/favicon.ico
	rm logo.png logo256.png logo16.png logo32.png logo48.png
