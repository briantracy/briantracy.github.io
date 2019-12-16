

.PHONY: all render compress publish

export SITE_ROOT = $(shell pwd)

all: render publish

render:
	./_site/render-markdown

publish:
	gitpub

