

.PHONY: all render publish

export REPO_ROOT = $(shell pwd)

all: render site_map publish

render:
	./_site/render-markdown

site_map:
	tree -H https://briantracy.xyz > full-tree.html

publish:
	gitpub

test: $(wildcard *.md **/*.md)
	@echo $^
