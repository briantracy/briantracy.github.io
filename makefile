


MARKDOWN_FILES := $(shell find . -name '*.md' -type f)
HTML_FILES     := $(addsuffix .html,$(basename $(MARKDOWN_FILES)))

HTML_TEMPLATE := _site/template.html
CSS_TEMPLATE  := _site/styles.css
SITE_CSS      := _site/compressed.css

render: $(SITE_CSS) $(HTML_FILES)

$(SITE_CSS): $(CSS_TEMPLATE)
	sass --style=compressed --no-source-map $< $@

%.html: %.md
	@echo "***\033[0;32mCOMPILING\033[0m***" $<
	@pandoc --to html5 --from markdown-auto_identifiers-smart \
			--template=$(HTML_TEMPLATE) \
			--include-in-header=$(SITE_CSS) \
			--metadata title="Brian Tracy - $(basename $base_name)" \
			--metadata date="$(shell stat -f '%Sm' $<)" \
			--ascii "$<" \
	| html-minifier \
			--no-html5 \
			--collapse-whitespace \
			--remove-comments \
			--output "$@"

clean:
	rm -f $(HTML_FILES)
