

.PHONY: publish

publish:
	git add .
	git commit -m "automated website commit: `date`"
	git push
