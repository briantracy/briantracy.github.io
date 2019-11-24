

.PHONY: all render compress publish


all: render compress publish

publish:
	git add .
	git commit -m "automated website commit: `date`"
	git push

render:
	bash render.sh

compress:
	echo "compressing images"
