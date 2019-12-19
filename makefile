

.PHONY: all render publish

export REPO_ROOT = $(shell pwd)

all: render site_map publish

render:
	./_site/render-markdown

site_map:
	tree -H / > full_tree.html

publish:
	gitpub

