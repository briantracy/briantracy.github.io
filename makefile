
MARKDOWN_FILES := $(shell find . -name '*.md' -type f)
HTML_FILES     := $(addsuffix .html,$(basename $(MARKDOWN_FILES)))

HTML_TEMPLATE := _site/template.html
CSS_TEMPLATE  := _site/styles.css
SITE_CSS      := _site/compressed.css

.PHONY: clean serve validate validate-online

render: $(HTML_FILES)

$(SITE_CSS): $(CSS_TEMPLATE)
	sass --style=compressed --no-source-map "$<" "$@"

%.html: %.md $(HTML_TEMPLATE) $(SITE_CSS)
	@echo "[\033[0;32mCOMPILING\033[0m]" $<
	@pandoc --to html5 --from markdown-auto_identifiers-smart \
			--template=$(HTML_TEMPLATE) \
			--include-in-header=$(SITE_CSS) \
			--metadata title="Brian Tracy - $(notdir $(basename $<))" \
			--metadata date="$(shell stat -f '%Sm' $<)" \
			--ascii "$<" --output "$@"
#	| html-minifier \
#			--no-html5 \
#			--collapse-whitespace \
#			--remove-comments \
#			--output "$@"

clean:
	rm -f $(HTML_FILES)

serve: render
	open -a Firefox.app http://localhost:8080
	python3 -m http.server 8080


# Submit each *on disk* file to the html validator
validate:
	@for file in $(HTML_FILES); do \
		echo "[\033[0;33mCHECKING\033[0m] $$file" ; \
		curl -F out=gnu -F "file=@$$file" https://validator.w3.org/nu/ ; \
	done


# Ask the html validator to look at each *on line* file (it will scrape)
validate-online:
	@for file in $(HTML_FILES); do \
		echo "[\033[0;33mCHECKING\033[0m] $$file" ; \
		curl "https://validator.w3.org/nu/?doc=https://briantracy.xyz/$$file&out=gnu" ; \
	done

