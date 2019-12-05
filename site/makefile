

.PHONY: all render compress publish

export SITE_ROOT = $(shell pwd)

all: render compress publish

publish:
	git add .
	git commit -m "automated website commit: `date`"
	git push

render:
	./scripts/render-markdown

compress:
	echo "compressing images"
