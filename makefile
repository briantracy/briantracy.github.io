

.PHONY: all render compress publish

export REPO_ROOT = $(shell pwd)

all: render publish

render:
	./_site/render-markdown

publish:
	gitpub

