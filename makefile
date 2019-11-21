

.PHONY: all render compress publish


all: render compress publish

publish:
	echo "publishing"
	exit 0
	git add .
	git commit -m "automated website commit: `date`"
	git push

render:
	echo "rendering markdown"

compress:
	echo "compressing images"
